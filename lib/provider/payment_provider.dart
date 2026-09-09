import 'dart:async';

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
  bool _isPaymentInProgress = false;
  String? _currentOrderId;
  bool _cancelRequested = false;
  bool _isCancellationInProgress = false;
  int _activePaymentFlowId = 0;
  StreamSubscription<OrderStatusResponse>? _orderStatusSubscription;

  PaymentProvider(this._paymentService, this._itemService, this._chargeService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<NonBarcodeItemResponse> get nonBarcodeItems => _nonBarcodeItems;
  List<ItemResponse> get allItems => _allItems;
  int get chargeAmount => _chargeAmount;

  /// 결제 요청이 진행 중인지 여부.
  ///
  /// 결제 요청을 보낸 직후(아직 응답이 도착하지 않은 찰나의 시간 포함)부터
  /// 처리가 완전히 종료될 때까지 true. UI는 이 값을 이용해 사용자 입력을
  /// 차단(hidden 상태로 만들지 않고 터치만 막음)하여 결제 도중 다른 조작이
  /// 꼬이는 것을 방지한다.
  bool get isPaymentInProgress => _isPaymentInProgress;

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
    final totalStopwatch = Stopwatch()..start();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await _cancelOrderStatusSubscription();
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
    _isPaymentInProgress = true;
    _currentOrderId = null;
    _cancelRequested = false;
    _isCancellationInProgress = false;
    notifyListeners();

    _logger.info('⏱️ [PAYMENT] 결제 프로세스 시작 - 상품 ${cartSnapshot.length}개');

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

      final orderCreationStopwatch = Stopwatch()..start();
      final createdOrder = await _paymentService.createOrder(
        items: cartSnapshot,
        isGuestMode: authProvider.isGuestMode,
      );
      orderCreationStopwatch.stop();
      _logger.info(
        '⏱️ [PAYMENT] 주문 생성 완료 - ${orderCreationStopwatch.elapsedMilliseconds}ms, '
        'orderId: ${createdOrder.orderId}',
      );
      _currentOrderId = createdOrder.orderId;

      if (!_isSameFlow(flowId)) {
        return;
      }

      if (_cancelRequested) {
        _logger.info('🚫 [CANCEL] 주문 생성 후 취소 요청 감지 - cancelRequested 처리');
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

      final finalOrder = await _watchOrderUntilTerminal(
        createdOrder.orderId,
      );

      totalStopwatch.stop();
      _logger.info(
        '⏱️ [PAYMENT] 결제 프로세스 완료 - 총 ${totalStopwatch.elapsedMilliseconds}ms, '
        '최종 상태: ${finalOrder.status}',
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
      totalStopwatch.stop();
      _logger.severe(
        '⏱️ [PAYMENT] 결제 프로세스 실패 - ${totalStopwatch.elapsedMilliseconds}ms',
      );
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

      // /items/without-barcode 응답에는 category가 없으므로, /items(전체 상품) 응답에서
      // itemId 기준으로 category를 보강한다. /items 조회가 실패해도 원래 목록은 그대로 사용.
      final categoryById = <int, String>{};
      try {
        final allItems = await _itemService.getAllItems();
        for (final item in allItems) {
          if (item.itemCategory.isNotEmpty) {
            categoryById[item.itemId] = item.itemCategory;
          }
        }
      } catch (e) {
        _logger.warning('바코드 없는 상품 카테고리 보강 실패: $e');
      }

      _nonBarcodeItems.clear();
      _nonBarcodeItems.addAll(items.map((item) {
        final category = categoryById[item.itemId];
        if (category == null || item.itemCategory.isNotEmpty) {
          return item;
        }
        return NonBarcodeItemResponse(
          itemId: item.itemId,
          itemCode: item.itemCode,
          itemName: item.itemName,
          itemPrice: item.itemPrice,
          eventStatus: item.eventStatus,
          itemCategory: category,
        );
      }));
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
    _logger.info(
      '🚫 [CANCEL] cancelPayment 호출 - '
      'isCancellationInProgress: $_isCancellationInProgress, '
      'currentOrderId: $_currentOrderId',
    );

    if (_isCancellationInProgress) {
      _logger.info('🚫 [CANCEL] 이미 취소 진행 중 - 무시');
      return;
    }

    if (_currentOrderId == null) {
      _cancelRequested = true;
      _logger.info('🚫 [CANCEL] 주문 생성 대기 중 - cancelRequested = true');
      return;
    }

    _logger.info('🚫 [CANCEL] _cancelCurrentOrder 호출 시작');

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

  Future<OrderStatusResponse> _watchOrderUntilTerminal(String orderId) async {
    final completer = Completer<OrderStatusResponse>();
    OrderStatusResponse? lastStatus;
    final watchStopwatch = Stopwatch()..start();
    String? previousStatus;
    DateTime? previousStatusTime;

    _logger.info('⏱️ [ORDER] 주문 상태 감시 시작 - orderId: $orderId');

    await _cancelOrderStatusSubscription();
    _orderStatusSubscription = _paymentService.watchOrderStatus(orderId).listen(
      (status) {
        final now = DateTime.now();
        if (previousStatus != null && previousStatusTime != null) {
          final transitionMs =
              now.difference(previousStatusTime!).inMilliseconds;
          _logger.info(
            '⏱️ [ORDER] 상태 전이: $previousStatus → ${status.status} '
            '(${transitionMs}ms)',
          );
        } else {
          _logger.info(
            '⏱️ [ORDER] 초기 상태 수신: ${status.status} '
            '(${watchStopwatch.elapsedMilliseconds}ms)',
          );
        }
        previousStatus = status.status;
        previousStatusTime = now;
        lastStatus = status;
      },
      onDone: () {
        watchStopwatch.stop();
        _logger.info(
          '⏱️ [ORDER] 주문 상태 감시 종료 - orderId: $orderId, '
          '총 소요: ${watchStopwatch.elapsedMilliseconds}ms, '
          '최종 상태: ${lastStatus?.status ?? "UNKNOWN"}',
        );

        if (completer.isCompleted) {
          return;
        }

        if (lastStatus != null && lastStatus!.isTerminal) {
          completer.complete(lastStatus);
          return;
        }

        completer.completeError(
          StateError('주문 상태 스트림이 최종 상태 없이 종료되었습니다.'),
        );
      },
      onError: (Object e) {
        watchStopwatch.stop();
        _logger.warning(
          '⏱️ [ORDER] 주문 상태 감시 에러 - ${watchStopwatch.elapsedMilliseconds}ms',
        );
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
    );

    return completer.future;
  }

  void _resetPaymentFlowState() {
    final wasInProgress = _isPaymentInProgress;
    _isProcessingDialogVisible = false;
    _isPaymentInProgress = false;
    _currentOrderId = null;
    _cancelRequested = false;
    _isCancellationInProgress = false;
    unawaited(_cancelOrderStatusSubscription());
    if (wasInProgress) {
      notifyListeners();
    }
  }

  Future<void> _cancelOrderStatusSubscription() async {
    await _orderStatusSubscription?.cancel();
    _orderStatusSubscription = null;
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

    if (!context.mounted) {
      return;
    }
    await _closeProcessingDialog(context);

    authProvider.clearCart();

    if (!context.mounted) {
      return;
    }

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) =>
          PaymentResultDialog(
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
    _logger.info(
      '🚫 [CANCEL] _cancelCurrentOrder 진입 - orderId: $orderId',
    );
    if (orderId == null) {
      _cancelRequested = true;
      _logger.info('🚫 [CANCEL] orderId가 null - cancelRequested = true');
      return;
    }

    _isCancellationInProgress = true;
    // SSE 구독 취소는 백그라운드에서 처리 — cancel API를 먼저 호출
    unawaited(_cancelOrderStatusSubscription());

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

    // 취소 API 응답이 CANCEL_REQUESTED이면 즉시 취소 완료로 처리 (SSE 대기 불필요)
    final isCancelCompleted =
        cancelResponse.status == OrderStatus.cancelRequested ||
            cancelResponse.status == OrderStatus.cancelled;

    final finalStatus = (cancelResponse.isTerminal || isCancelCompleted)
        ? cancelResponse
        : await _paymentService.watchOrderStatus(orderId).last;

    if (!_isSameFlow(flowId)) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    // isCancelled를 먼저 계산하고 cart를 비운다.
    // _closeProcessingDialog 이후 context가 unmount될 수 있으므로 그 이전에 처리.
    final isCancelled = finalStatus.status == OrderStatus.cancelled ||
        finalStatus.status == OrderStatus.cancelRequested;

    if (isCancelled && authProvider.isGuestMode) {
      authProvider.clearCart();
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

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) =>
          PaymentResultDialog(
        errorMessage: errorMessage,
        errorCode: errorCode,
        isSuccess: false,
        shouldReturnToHome: !isCancelled,
      ),
    );

    if (context.mounted && !isCancelled) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    unawaited(_cancelOrderStatusSubscription());
    super.dispose();
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

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) =>
          PaymentResultDialog(
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
