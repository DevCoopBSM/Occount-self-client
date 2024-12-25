import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../services/item_service.dart';
import 'package:logging/logging.dart';
import '../models/cart_item.dart';
import '../models/non_barcode_item_response.dart';
import '../services/charge_service.dart';
import '../ui/payments/widgets/payment_processing_dialog.dart';
import '../ui/payments/widgets/payment_result_dialog.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
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
  bool _isProcessingDialogVisible = false;

  PaymentProvider(this._paymentService, this._itemService, this._chargeService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<NonBarcodeItemResponse> get nonBarcodeItems => _nonBarcodeItems;
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
        _logger.info('🔄 기존 상품 수량 증가: ${item.itemName}');
      } else {
        // 새로운 상품이면 장바구니에 추가
        final cartItem = CartItem.fromItemResponse(item);
        authProvider.addToCart(cartItem);
        _logger.info('➕ 새 상품 추가: ${item.itemName}');
      }
    } catch (e) {
      _error = '상품 추가에 실패했습니다';
      _logger.severe('상품 추가 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> processPayment({
    required String userCode,
    required String userName,
    required BuildContext context,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 상품이 없는 경우 먼저 체크
    if (authProvider.cartItems.isEmpty) {
      _logger.info('⚠️ 상품이 없는 상태에서 결제 시도');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품을 추가해주세요')),
        );
      }
      return;
    }

    _isProcessingDialogVisible = true;

    // 결제 진행 중 모달 표시
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final calculation = calculatePayment(
              authProvider.cartItems, authProvider.userInfo.userPoint);

          return PaymentProcessingDialog(
            totalAmount: calculation.totalPrice,
            paymentAmount: calculation.expectedPoints,
            cardAmount: calculation.expectedCardAmount,
            isChargeOnly: calculation.isChargeOnly,
            hasCharge: calculation.hasCharge,
            onClose: () {
              cancelPayment(context);
              Navigator.of(context).pop();
            },
          );
        },
      );
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.cartItems.isEmpty) {
        _logger.info('⚠️ 상품이 없는 상태에서 결제 시도');
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => PaymentProcessingDialog(
              totalAmount: 0,
              paymentAmount: 0,
              cardAmount: 0,
              isChargeOnly: false,
              hasCharge: false,
              onClose: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('상품을 추가해주세요')),
                );
              },
            ),
          );
        }
        return;
      }

      // 결제 API 요청
      _logger.info('💰 결제 API 요청 시작');
      final result = await _paymentService.executePayment(
        items: authProvider.cartItems,
        userCode: userCode,
        userName: userName,
      );

      // 모달이 이미 닫혔다면 응답 처리하지 않음
      if (!_isProcessingDialogVisible) {
        _logger.info('💡 결제 진행 중 모달이 닫혀 응답을 무시합니다');
        return;
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // 진행 중 모달 닫기
      }

      // 결제 완료 후 장바구니 초기화
      authProvider.clearCart();

      // 결제 결과 다이얼로그 표시
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PaymentResultDialog(
            response: result,
            isSuccess: result.success,
            shouldReturnToHome: true,
          ),
        );

        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/scan',
            (route) => false,
          );
        }
      }
    } catch (e) {
      _logger.severe('❌ 결제 처리 실패: $e');

      // 모달이 이미 닫혔다면 에러 처리하지 않음
      if (!_isProcessingDialogVisible) {
        _logger.info('💡 결제 진행 중 모달이 닫혀 에러를 무시합니다');
        return;
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // 진행 중 모달 닫기

        String errorMessage;
        String errorCode = '';
        bool shouldReturnToHome = false;

        if (e is ApiException) {
          errorMessage = e.message;
          errorCode = e.code.code;
          // 타임아웃이나 결제 실패의 경우 장바구니 유지
          shouldReturnToHome = ![
            ApiErrorCode.paymentTimeout,
            ApiErrorCode.paymentFailed,
            ApiErrorCode.paymentCancelled,
          ].contains(e.code);
        } else if (e is PaymentException) {
          errorMessage = e.message;
          errorCode = e.code;
          shouldReturnToHome =
              !['PAYMENT_TIMEOUT', 'PAYMENT_FAILED'].contains(e.code);
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

        // 홈으로 돌아가야 하는 경우에만 네비게이션 실행
        if (shouldReturnToHome && context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/scan',
            (route) => false,
          );
        }
      }
    } finally {
      _isProcessingDialogVisible = false;
    }
  }

  int calculateTotalPrice(List<CartItem> items) {
    return items.fold<int>(
      0,
      (sum, item) => sum + (item.itemPrice * item.quantity),
    );
  }

  Future<PaymentResponse> executePayment({
    required String userCode,
    required String userName,
    required List<CartItem> items,
  }) async {
    final totalPrice = calculateTotalPrice(items);
    _logger.info('💰 결제 요청 시작');
    _logger.info('사용자: $userName ($userCode)');
    _logger.info('총 결제금액: $totalPrice원');

    return await _paymentService.executePayment(
      items: items,
      userCode: userCode,
      userName: userName,
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

  Future<void> cancelPayment(BuildContext context) async {
    try {
      _logger.info('💡 결제가 취소되었습니다');
      _isProcessingDialogVisible = false;

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _logger.severe('❌ 결제 취소 실패: $e');
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
      _logger.info('🔄 기존 상품 수량 증가: ${item.itemName}');
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
      _logger.info('➕ 새 상품 추가: ${item.itemName}');
    }
  }

  Future<void> retryPayment(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await processPayment(
      userCode: authProvider.userInfo.userCode,
      userName: authProvider.userInfo.userName,
      context: context,
    );
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
