import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../services/item_service.dart';
import 'package:logging/logging.dart';
import '../models/cart_item.dart';
import '../models/non_barcode_item_response.dart';
import '../models/item_response.dart';
import '../services/charge_service.dart';
import '../ui/payments/widgets/payment_processing_dialog.dart';
import '../ui/payments/widgets/payment_result_dialog.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../models/order_status_response.dart';
import '../models/payment_response.dart';
import '../exception/payment_exception.dart';
import '../exception/api_exception.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService;
  final ItemService _itemService;
  final ChargeService _chargeService;
  final Logger _logger = Logger('PaymentProvider');

  bool _isLoading = false;
  String? _error;
  int _chargeAmount = 0;
  final List<NonBarcodeItemResponse> _nonBarcodeItems = [];
  final List<ItemResponse> _allItems = [];
  bool _isProcessingDialogVisible = false;
  String? _currentOrderId;
  bool _cancelRequested = false;
  bool _isCancellationInProgress = false;
  int _activePaymentFlowId = 0;

  PaymentProvider(this._paymentService, this._itemService, this._chargeService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<NonBarcodeItemResponse> get nonBarcodeItems => _nonBarcodeItems;
  List<ItemResponse> get allItems => _allItems;
  int get chargeAmount => _chargeAmount;

  void addChargeAmount(int amount) {
    _chargeAmount += amount;
    notifyListeners();
  }

  void resetChargeAmount() {
    _chargeAmount = 0;
    notifyListeners();
  }

  void confirmCharge(BuildContext context) {
    if (_chargeService.isValidChargeAmount(_chargeAmount)) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.cartItems.removeWhere(
          (item) => item.itemCategory == ChargeService.chargeItemType);

      final chargeItem = _chargeService.createChargeItem(_chargeAmount);
      authProvider.addToCart(chargeItem);
      resetChargeAmount();
    }
  }

  Future<void> addItemByBarcode(String barcode, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final item = await _itemService.getItemByCode(barcode);
      if (!context.mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 이미 장바구니에 있는 상품인지 확인
      final existingItemIndex = authProvider.cartItems
          .indexWhere((cartItem) => cartItem.itemCode == item.itemCode);

      if (existingItemIndex != -1) {
        // 이미 있는 상품이면 수량만 증가
        authProvider
            .increaseQuantity(authProvider.cartItems[existingItemIndex].itemId);
      } else {
        // 새로운 상품이면 장바구니에 추가
        final cartItem = CartItem.fromItemResponse(item);
        authProvider.addToCart(cartItem);
      }
    } catch (e) {
      _error = '상품 추가에 실패했습니다';
      _logger.severe('상품 추가 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 명세서 변경: userCode, userName 제거 — 토큰 기반 인증으로 서버가 사용자 식별
  Future<void> processPayment({
    required BuildContext context,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final flowId = ++_activePaymentFlowId;
    final cartSnapshot = authProvider.cartItems
        .map((item) => item.copyWith())
        .toList(growable: false);

    // 상품이 없는 경우 먼저 체크
    if (cartSnapshot.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품을 추가해주세요')),
        );
      }
      return;
    }

    authProvider.pauseSessionTimer();

    _isProcessingDialogVisible = true;
    _currentOrderId = null;
    _cancelRequested = false;
    _isCancellationInProgress = false;

    // 결제 진행 중 모달 표시
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final calculation = calculatePayment(
            cartSnapshot,
            authProvider.userInfo.userPoint,
          );

          return PaymentProcessingDialog(
            totalAmount: calculation.totalPrice,
            paymentAmount: calculation.expectedPoints,
            cardAmount: calculation.expectedCardAmount,
            // 명세서 변경: CHARGE 타입 제거 — 항상 false
            isChargeOnly: false,
            hasCharge: false,
            onClose: () {
              cancelPayment(context);
            },
          );
        },
      );
    }

    try {
      if (cartSnapshot.isEmpty) {
        return;
      }

      final createdOrder = await _paymentService.createOrder(
        items: cartSnapshot,
        isGuestMode: authProvider.isGuestMode,
      );
      _currentOrderId = createdOrder.orderId;

      if (!_isSameFlow(flowId)) {
        return;
      }

      if (_cancelRequested) {
        if (!context.mounted) {
          return;
        }
        await _cancelCurrentOrder(
          context: context,
          authProvider: authProvider,
          flowId: flowId,
        );
        return;
      }

      final finalOrder = await _paymentService.pollOrderStatusUntilFinal(
        createdOrder.orderId,
        initialDelay: PaymentService.initialOrderPollingDelay,
      );

      if (!_isSameFlow(flowId) || _isCancellationInProgress) {
        return;
      }

      if (!context.mounted) {
        return;
      }
      await _handleOrderResult(
        context: context,
        authProvider: authProvider,
        orderStatus: finalOrder,
        cartItems: cartSnapshot,
      );
    } catch (e) {
      _logger.severe('❌ 결제 처리 실패: $e');
      _logger.severe('❌ 에러 타입: ${e.runtimeType}');

      if (e is ApiException) {
        _logger
            .severe('❌ [ApiException] 코드: ${e.code.code}, 메시지: ${e.message}');
      }
      if (e is PaymentException) {
        _logger.severe('❌ [PaymentException] 코드: ${e.code}, 메시지: ${e.message}');
      }

      if (!_isSameFlow(flowId) || _isCancellationInProgress) {
        return;
      }

      if (!context.mounted) {
        return;
      }
      await _handlePaymentError(context: context, error: e);
    } finally {
      if (_isSameFlow(flowId) && !_isCancellationInProgress) {
        _resetPaymentFlowState();
      }
    }
  }

  int calculateTotalPrice(List<CartItem> items) {
    return items.fold<int>(
      0,
      (sum, item) => sum + (item.itemPrice * item.quantity),
    );
  }

  Future<PaymentResponse> executePayment({
    required List<CartItem> items,
    required int userPoint,
  }) async {
    return await _paymentService.executePayment(
      items: items,
      userPoint: userPoint,
    );
  }

  int getSingleChargeAmount(List<CartItem> items) {
    final chargeItem = items.firstWhere(
      (item) => item.itemCategory == 'CHARGE',
      orElse: () => CartItem(
        itemId: -1,
        itemCode: '',
        itemName: '',
        quantity: 0,
        itemPrice: 0,
        itemCategory: '',
      ),
    );
    return chargeItem.itemPrice;
  }

  PaymentCalculation calculatePayment(List<CartItem> items, int currentPoints) {
    final totalPrice = calculateTotalPrice(items);
    final hasCharge = items.any((item) => item.itemCategory == 'CHARGE');
    final isChargeOnly = items.every((item) => item.itemCategory == 'CHARGE');

    if (hasCharge) {
      final chargeAmount = getSingleChargeAmount(items);
      return PaymentCalculation(
        totalPrice: totalPrice,
        chargeAmount: chargeAmount,
        expectedPoints: 0,
        expectedCardAmount: totalPrice,
        isChargeOnly: isChargeOnly,
        hasCharge: true,
      );
    }

    final availablePoints = currentPoints;
    final expectedPoints =
        totalPrice <= availablePoints ? totalPrice : availablePoints;
    final expectedCardAmount =
        totalPrice <= availablePoints ? 0 : totalPrice - availablePoints;

    return PaymentCalculation(
      totalPrice: totalPrice,
      chargeAmount: 0,
      expectedPoints: expectedPoints,
      expectedCardAmount: expectedCardAmount,
      isChargeOnly: false,
      hasCharge: false,
    );
  }

  Future<void> loadNonBarcodeItems() async {
    try {
      _isLoading = true;
      notifyListeners();

      final items = await _itemService.getNonBarcodeItems();
      _nonBarcodeItems.clear();
      _nonBarcodeItems.addAll(items);
    } catch (e) {
      _error = '바코드 없는 상품 목록을 불러오는데 실패했습니다';
      _logger.severe('바코드 없는 상품 로드 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllItems() async {
    try {
      _isLoading = true;
      notifyListeners();

      final items = await _itemService.getAllItems();
      _allItems.clear();
      _allItems.addAll(items);
      _error = null;
    } catch (e) {
      _error = '전체 상품 목록을 불러오는데 실패했습니다';
      _logger.severe('전체 상품 로드 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addAllItem(BuildContext context, ItemResponse item) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 이미 장바구니에 있는 아이템인지 확인
    final existingItemIndex = authProvider.cartItems
        .indexWhere((cartItem) => cartItem.itemId == item.itemId);

    if (existingItemIndex != -1) {
      // 이미 있는 아이템이면 수량만 증가
      authProvider.increaseQuantity(item.itemId);
    } else {
      // 새 아이템이면 장바구니에 추가
      final cartItem = CartItem(
        itemId: item.itemId,
        itemCode: item.itemCode,
        itemName: item.itemName,
        itemPrice: item.itemPrice,
        itemCategory: item.itemCategory,
        quantity: 1,
      );
      authProvider.addToCart(cartItem);
    }
  }

  Future<void> cancelPayment(BuildContext context) async {
    if (_isCancellationInProgress) {
      return;
    }

    if (_currentOrderId == null) {
      _cancelRequested = true;
      _logger.info('🕒 주문 생성 응답 대기 중 - 생성 완료 후 취소 요청 예정');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await _cancelCurrentOrder(
        context: context,
        authProvider: authProvider,
        flowId: _activePaymentFlowId,
      );
    } catch (e) {
      _logger.severe('❌ 결제 취소 실패: $e');
      if (!context.mounted) {
        return;
      }
      await _handlePaymentError(context: context, error: e);
    } finally {
      _resetPaymentFlowState();
    }
  }

  void addNonBarcodeItem(BuildContext context, NonBarcodeItemResponse item) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 이미 장바구니에 있는 아이템인지 확인
    final existingItemIndex = authProvider.cartItems
        .indexWhere((cartItem) => cartItem.itemId == item.itemId);

    if (existingItemIndex != -1) {
      // 이미 있는 아이템이면 수량만 증가
      authProvider.increaseQuantity(item.itemId);
    } else {
      // 새 아이템이면 장바구니에 추가
      final cartItem = CartItem(
        itemId: item.itemId,
        itemName: item.itemName,
        itemPrice: item.itemPrice,
        itemCode: item.itemCode,
        quantity: 1,
        itemCategory: item.itemCategory,
      );
      authProvider.addToCart(cartItem);
    }
  }

  Future<void> retryPayment(BuildContext context) async {
    await processPayment(context: context);
  }

  bool _isSameFlow(int flowId) => _activePaymentFlowId == flowId;

  void _resetPaymentFlowState() {
    _isProcessingDialogVisible = false;
    _currentOrderId = null;
    _cancelRequested = false;
    _isCancellationInProgress = false;
  }

  Future<void> _closeProcessingDialog(BuildContext context) async {
    if (!_isProcessingDialogVisible || !context.mounted) {
      return;
    }

    _isProcessingDialogVisible = false;

    try {
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {
      // 이미 닫힌 경우 무시
    }

    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _handleOrderResult({
    required BuildContext context,
    required AuthProvider authProvider,
    required OrderStatusResponse orderStatus,
    required List<CartItem> cartItems,
  }) async {
    switch (orderStatus.status) {
      case OrderStatus.completed:
        await _handleCompletedOrder(
          context: context,
          authProvider: authProvider,
          cartItems: cartItems,
        );
        return;
      case OrderStatus.failed:
        throw ApiException.fromErrorCode(
          ApiErrorCode.paymentFailed,
          orderStatus.failureReason ?? '결제에 실패했습니다.',
        );
      case OrderStatus.cancelled:
        throw ApiException.fromErrorCode(
          ApiErrorCode.paymentCancelled,
          orderStatus.failureReason ?? '주문이 취소되었습니다.',
        );
      case OrderStatus.compensationFailed:
        throw PaymentException(
          code: 'COMPENSATION_FAILED',
          message: orderStatus.failureReason ?? '오류가 발생했습니다. 관리자에게 문의하세요.',
          status: 500,
        );
      case OrderStatus.timedOut:
        throw ApiException.fromErrorCode(
          ApiErrorCode.paymentTimeout,
          '처리 시간이 초과되었습니다.',
        );
      default:
        throw ApiException.fromErrorCode(
          ApiErrorCode.serverError,
          '결제 상태를 확인하는 중 오류가 발생했습니다.',
        );
    }
  }

  Future<void> _handleCompletedOrder({
    required BuildContext context,
    required AuthProvider authProvider,
    required List<CartItem> cartItems,
  }) async {
    final calculation =
        calculatePayment(cartItems, authProvider.userInfo.userPoint);

    if (!authProvider.isGuestMode) {
      try {
        await authProvider.updatePoint();
      } catch (e) {
        _logger.warning('⚠️ 결제 후 포인트 갱신 실패: $e');
      }
    }

    final result = PaymentResponse(
      success: true,
      message: '주문이 정상처리되었습니다',
      type: calculation.expectedCardAmount > 0 ? 'MIXED' : 'POINT',
      chargedAmount: calculation.expectedCardAmount,
      remainingPoints: authProvider.userInfo.userPoint,
      totalAmount: calculation.totalPrice,
      pointsUsed: calculation.expectedPoints,
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) {
      return;
    }
    await _closeProcessingDialog(context);

    authProvider.clearCart();

    if (!context.mounted) {
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentResultDialog(
        response: result,
        isSuccess: true,
        shouldReturnToHome: true,
      ),
    );

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    }
  }

  Future<void> _cancelCurrentOrder({
    required BuildContext context,
    required AuthProvider authProvider,
    required int flowId,
  }) async {
    final orderId = _currentOrderId;
    if (orderId == null) {
      _cancelRequested = true;
      return;
    }

    _isCancellationInProgress = true;

    OrderStatusResponse cancelResponse;
    try {
      cancelResponse = await _paymentService.cancelOrder(
        orderId: orderId,
        isGuestMode: authProvider.isGuestMode,
      );
    } on ApiException catch (e) {
      if (e.code != ApiErrorCode.conflict) {
        rethrow;
      }

      _logger.info('ℹ️ 취소 요청 중 상태 경합 발생 - 최종 주문 상태 재조회');
      cancelResponse = await _paymentService.getOrderStatus(orderId);
    }

    final finalStatus = cancelResponse.isTerminal
        ? cancelResponse
        : await _paymentService.pollOrderStatusUntilFinal(orderId);

    if (!_isSameFlow(flowId)) {
      return;
    }

    if (!context.mounted) {
      return;
    }
    await _closeProcessingDialog(context);

    if (!context.mounted) {
      return;
    }

    if (finalStatus.status == OrderStatus.completed) {
      await _handleCompletedOrder(
        context: context,
        authProvider: authProvider,
        cartItems: authProvider.cartItems
            .map((item) => item.copyWith())
            .toList(growable: false),
      );
      return;
    }

    final isCancelled = finalStatus.status == OrderStatus.cancelled;
    final isCompensationFailed =
        finalStatus.status == OrderStatus.compensationFailed;
    final isTimedOut = finalStatus.status == OrderStatus.timedOut;
    final errorMessage = isCancelled
        ? (finalStatus.failureReason ?? '주문이 취소되었습니다.')
        : isCompensationFailed
            ? (finalStatus.failureReason ?? '오류가 발생했습니다. 관리자에게 문의하세요.')
            : isTimedOut
                ? '처리 시간이 초과되었습니다.'
                : (finalStatus.failureReason ?? '결제에 실패했습니다.');
    final errorCode = isCancelled
        ? ApiErrorCode.paymentCancelled.code
        : isCompensationFailed
            ? 'COMPENSATION_FAILED'
            : isTimedOut
                ? ApiErrorCode.paymentTimeout.code
                : ApiErrorCode.paymentFailed.code;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentResultDialog(
        errorMessage: errorMessage,
        errorCode: errorCode,
        isSuccess: false,
        shouldReturnToHome: !isCancelled,
      ),
    );

    if (context.mounted) {
      if (isCancelled) {
        Navigator.of(context).pop();
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
      }
    }
  }

  Future<void> _handlePaymentError({
    required BuildContext context,
    required Object error,
  }) async {
    await _closeProcessingDialog(context);

    if (!context.mounted) {
      return;
    }

    String errorMessage;
    String errorCode = '';
    bool shouldReturnToHome = false;

    if (error is ApiException) {
      errorMessage = error.message;
      errorCode = error.code.code;
      shouldReturnToHome = ![
        ApiErrorCode.paymentTimeout,
        ApiErrorCode.paymentFailed,
      ].contains(error.code);
    } else if (error is PaymentException) {
      errorMessage = error.message;
      errorCode = error.code;
      shouldReturnToHome =
          !['PAYMENT_TIMEOUT', 'PAYMENT_FAILED'].contains(error.code);
    } else {
      errorMessage = '결제 처리 중 오류가 발생했습니다';
      shouldReturnToHome = true;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentResultDialog(
        errorMessage: errorMessage,
        errorCode: errorCode,
        isSuccess: false,
        shouldReturnToHome: shouldReturnToHome,
      ),
    );

    if (shouldReturnToHome && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    }
  }
}

// 계산 결과를 담는 클래스
class PaymentCalculation {
  final int totalPrice;
  final int chargeAmount;
  final int expectedPoints;
  final int expectedCardAmount;
  final bool isChargeOnly;
  final bool hasCharge;

  PaymentCalculation({
    required this.totalPrice,
    required this.chargeAmount,
    required this.expectedPoints,
    required this.expectedCardAmount,
    required this.isChargeOnly,
    required this.hasCharge,
  });
}
