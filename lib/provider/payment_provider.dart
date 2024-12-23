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
import '../main.dart'; // globalNavigatorKey를 위한 import

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService;
  final ItemService _itemService;
  final ChargeService _chargeService;
  final Logger _logger = Logger('PaymentProvider');

  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;
  int _chargeAmount = 0;
  final List<NonBarcodeItemResponse> _nonBarcodeItems = [];

  PaymentProvider(this._paymentService, this._itemService, this._chargeService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isProcessing => _isProcessing;
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
      if (!context.mounted) return; // BuildContext 체크 추가

      final cartItem = CartItem.fromItemResponse(item);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.addToCart(cartItem);
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
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.cartItems.isEmpty) {
        _logger.info('⚠️ 상품이 없는 상태에서 결제 시도');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상품을 추가해주세요')),
          );
        }
        return;
      }

      _isProcessing = true;
      notifyListeners();

      // 결제 계산
      final calculation = calculatePayment(
        authProvider.cartItems,
        authProvider.userInfo.userPoint,
      );

      // 결제 진행 다이얼로그 표시
      if (!context.mounted) return;
      bool isProcessingDialogVisible = false;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          isProcessingDialogVisible = true;
          return PaymentProcessingDialog(
            totalAmount: calculation.totalPrice,
            paymentAmount: calculation.expectedPoints,
            cardAmount: calculation.expectedCardAmount,
            isChargeOnly: calculation.isChargeOnly,
          );
        },
      ).then((_) => isProcessingDialogVisible = false);

      try {
        final result = await executePayment(
          userCode: userCode,
          userName: userName,
          items: authProvider.cartItems,
        ).timeout(
          const Duration(seconds: 31),
          onTimeout: () {
            if (!isProcessingDialogVisible) {
              throw PaymentException(
                code: 'PAYMENT_CANCELED',
                message: '결제가 취소되었습니다.',
                status: 499,
              );
            }
            _logger.warning('⚠️ 결제 요청 타임아웃 (31초 초과)');
            throw PaymentException(
              code: 'PAYMENT_TIMEOUT',
              message: '결제 처리 시간이 초과되었습니다.\n잠시 후 다시 시도해주세요.',
              status: 408,
            );
          },
        );

        if (!context.mounted) return;
        // 프로세싱 다이얼로그 닫기
        Navigator.of(context).pop();

        // 결제 완료 후 장바구니 초기화
        authProvider.clearCart();

        // 결제 결과 다이얼로그 표시하고 결과 기다리기
        if (context.mounted) {
          final dialogResult = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) => PaymentResultDialog(
              response: result,
            ),
          );

          // 다이얼로그 결과에 따라 페이지 이동
          if (dialogResult == 'NAVIGATE_TO_SCAN' && context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/scan',
              (route) => false,
            );
          }
        }
      } catch (e) {
        _logger.severe('💳 결제 처리 중 오류 발생: $e');
        if (!context.mounted) return;

        // 프로세싱 다이얼로그 먼저 닫기
        Navigator.of(context).pop();

        // 에러 다이얼로그 표시
        if (context.mounted) {
          final dialogResult = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) => PaymentResultDialog(
              response: null,
              errorMessage: e is PaymentException
                  ? e.message // PaymentException의 메시지를 그대로 사용
                  : '결제 처리 중 오류가 발생했습니다.\n다시 시도해주세요.',
            ),
          );

          // 다이얼로그 결과에 따라 페이지 이동
          if (dialogResult == 'NAVIGATE_TO_SCAN' && context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/scan',
              (route) => false,
            );
          }
        }
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
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
    return await _paymentService.executePayment(
      items: items,
      userCode: userCode,
      userName: userName,
      totalPrice: calculateTotalPrice(items),
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

    // 충전 아이템이 있는 경우
    if (hasCharge) {
      final chargeAmount = getSingleChargeAmount(items);
      return PaymentCalculation(
        totalPrice: totalPrice,
        chargeAmount: chargeAmount,
        expectedPoints: 0, // 포인트 사용 안함
        expectedCardAmount: totalPrice, // 전체 금액 카드 결제
        isChargeOnly: isChargeOnly,
      );
    }

    // 일반 상품만 있는 경우
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
}

// 계산 결과를 담는 클래스
class PaymentCalculation {
  final int totalPrice;
  final int chargeAmount;
  final int expectedPoints;
  final int expectedCardAmount;
  final bool isChargeOnly;

  PaymentCalculation({
    required this.totalPrice,
    required this.chargeAmount,
    required this.expectedPoints,
    required this.expectedCardAmount,
    required this.isChargeOnly,
  });
}
