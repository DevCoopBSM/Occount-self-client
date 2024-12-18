import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dto/item_response_dto.dart';
import '../service/payment_service.dart';
import '../service/payment_calculation_service.dart';
import '../models/user_info.dart';
import 'package:flutter/material.dart';
import '../ui/payments/widgets/charge_dialog.dart';
import '../controller/user_controller.dart';
import '../models/payment_response.dart';
import '../ui/payments/widgets/payments_popup.dart';
import '../ui/_constant/util/number_format_util.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import '../exception/payment_exception.dart';

class PaymentController extends GetxController {
  final PaymentService _paymentService;
  final PaymentCalculationService _calculationService;
  final userController = Get.find<UserController>();
  final _logger = Logger('PaymentController');

  final TextEditingController barcodeController = TextEditingController();
  final FocusNode barcodeFocusNode = FocusNode();

  final RxList<ItemResponseDto> itemResponses = <ItemResponseDto>[].obs;
  final RxInt totalPrice = 0.obs;
  final RxBool isProcessing = false.obs;
  final RxBool isLoading = false.obs;
  final RxString selectedProductType = "바코드 없는 상품".obs;
  final RxInt chargeAmount = 0.obs;
  final RxList<ItemResponseDto> nonBarcodeItems = <ItemResponseDto>[].obs;

  PaymentController(this._paymentService, this._calculationService);

  @override
  void onInit() {
    super.onInit();
    loadNonBarcodeItems();
    barcodeFocusNode.requestFocus();
  }

  @override
  void onClose() {
    barcodeController.dispose();
    barcodeFocusNode.dispose();
    super.onClose();
  }

  Future<void> loadNonBarcodeItems() async {
    try {
      isLoading(true);
      final items = await _paymentService.getNonBarcodeItems();
      nonBarcodeItems.assignAll(items);
    } catch (e) {
      Get.snackbar('오류', '바코드 없는 상품 목록을 불러오는데 실패했습니다');
    } finally {
      isLoading(false);
    }
  }

  void addItem(ItemResponseDto item) {
    _logger.log(Level.INFO, '💫 addItem 호출: ${item.toJson()}');
    final existingIndex =
        itemResponses.indexWhere((i) => i.itemId == item.itemId);

    if (existingIndex != -1) {
      _logger.log(Level.INFO,
          '✏️ 기존 상품 수량 증가: ${itemResponses[existingIndex].itemName}');
      itemResponses[existingIndex].quantity += 1;
      itemResponses.refresh();
    } else {
      _logger.log(Level.INFO, '➕ 새 상품 추가: ${item.itemName}');
      itemResponses.add(item);
    }
    calculateTotalPrice();
    _logger.log(Level.INFO, '💰 현재 총액: ${totalPrice.value}원');
  }

  void removeItem(String itemId) {
    final index = itemResponses.indexWhere((i) => i.itemId == itemId);
    if (index != -1) {
      if (itemResponses[index].quantity > 1) {
        itemResponses[index].quantity -= 1;
        itemResponses.refresh();
      } else {
        itemResponses.removeAt(index);
      }
    }
    calculateTotalPrice();
  }

  void calculateTotalPrice() {
    totalPrice.value = itemResponses.fold(
        0, (sum, item) => sum + (item.itemPrice * item.quantity));
  }

  Future<void> processPayment() async {
    if (itemResponses.isEmpty) return;

    try {
      isProcessing(true);
      final isChargeRequest = _calculationService.hasChargeItem(itemResponses);
      final isChargeOnly =
          _calculationService.isChargeOnlyTransaction(itemResponses);

      String popupTitle;
      String popupMessage;
      final cardAmount = _calculationService.calculateCardAmount(
        items: itemResponses,
        totalPrice: totalPrice.value,
        currentPoints: currentUser.point,
      );

      if (isChargeRequest) {
        popupTitle = '충전 진행 중';
        popupMessage = '카드를 카드 리더기에 꽂아주세요.\n충전이 진행 중입니다.';
      } else {
        if (cardAmount > 0) {
          popupTitle = '카드 결제 진행 중';
          popupMessage = '카드를 카드 리더기에 꽂아주세요.\n결제가 진행 중입니다.';
        } else {
          popupTitle = '포인트 결제 진행 중';
          popupMessage = '포인트로 결제를 진행 중입니다.\n잠시만 기다려주세요.';
        }
      }

      Get.dialog(
        paymentProcessingPopup(
          Get.context!,
          title: popupTitle,
          message: popupMessage,
          cardAmount: cardAmount > 0
              ? "카드 결제 예정 금액: ${NumberFormatUtil.convert1000Number(cardAmount)}원"
              : null,
        ),
        barrierDismissible: false,
      );

      final response = await _paymentService
          .executePayment(
            items: itemResponses,
            userInfo: currentUser,
            totalAmount: totalPrice.value,
          )
          .timeout(
            const Duration(seconds: 35),
            onTimeout: () => throw TimeoutException('결제 처리 시간이 초과되었습니다'),
          );

      Get.back(); // 진행 중 팝업 닫기

      if (response.success) {
        _logger.log(Level.INFO, '✅ ${isChargeRequest ? "충전" : "결제"} 성공');
        userController.updateUserPoint(response.remainingPoints);

        String resultMessage = _calculationService.buildResultMessage(
          response: response,
          items: itemResponses, // items 파라미터 추가
          isChargeRequest: isChargeRequest,
          isChargeOnly: isChargeOnly,
          totalPrice: totalPrice.value,
          currentPoints: currentUser.point,
        );

        Get.dialog(
          paymentResultPopup(
            Get.context!,
            resultMessage,
            false,
            isCharge: isChargeRequest,
            totalAmount: response.totalAmount > 0
                ? response.totalAmount
                : response.chargedAmount,
            remainingPoints: response.remainingPoints,
          ),
          barrierDismissible: false,
        );

        await Future.delayed(const Duration(seconds: 2));
        Get.back();
        await loadNonBarcodeItems();
        clearItems();
        Get.offAllNamed('/');
      } else {
        _handlePaymentError(response);
      }
    } catch (e) {
      _handlePaymentException(e);
    } finally {
      isProcessing(false);
      _logger.log(Level.INFO, '🔄 결제 프로세스 종료');
    }
  }

  void _handlePaymentError(PaymentResponse response) {
    _logger.severe('❌ 결제 에러 처리: ${response.message}');
    Get.dialog(
      paymentResultPopup(
        Get.context!,
        response.message,
        true,
      ),
      barrierDismissible: false,
    );

    // 2초 후 결과 팝업 닫고 처음 화면으로
    Future.delayed(const Duration(seconds: 2), () {
      Get.back(); // 결과 팝업 닫기
      clearItems();
      Get.offAllNamed('/');
      _logger.info('✅ 에러 처리 완료: 초기 화면으로 이동');
    });
  }

  void clearItems() {
    itemResponses.clear();
    totalPrice.value = 0;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAllNamed('/');
  }

  void handleBarcodeSubmit() {
    final itemCode = barcodeController.text;
    if (itemCode.isEmpty) return;

    fetchItemData(itemCode, 1);
    barcodeController.clear();
    barcodeFocusNode.requestFocus();
  }

  Future<void> fetchItemData(String barcode, int quantity) async {
    try {
      final item = await _paymentService.getItemByBarcode(barcode);
      if (item != null) {
        addItem(item);
        _logger.info(
            '📦 상품 추가: ID=${item.itemId}, 이름=${item.itemName}, 가격=${item.itemPrice}원');
      } else {
        _logger.severe('❌ 바코드에 해당하는 상품을 찾을 수 없음: $barcode');
        Get.snackbar('알림', '해당 바코드의 상품을 찾을 수 없습니다');
      }
    } catch (e) {
      _logger.severe('❌ 상품 조회 에러: $e');
      Get.snackbar('오류', '상품 정보를 가져오는데 실패했습니다');
    }
  }

  void showChargeDialog() {
    Get.dialog(const ChargeDialog());
  }

  void addChargeAmount(int amount) {
    chargeAmount.value += amount;
  }

  void resetChargeAmount() {
    chargeAmount.value = 0;
  }

  void confirmCharge() {
    if (chargeAmount.value > 0) {
      final chargeItem = ItemResponseDto(
          itemName: "아리페이 충전",
          itemPrice: chargeAmount.value,
          itemId: "ARIPAY_CHARGE",
          quantity: 1,
          type: "CHARGE");

      addItem(chargeItem);
      Get.back(); // 다이얼로그 닫기
      resetChargeAmount();
    }
  }

  void addNonBarcodeItem(ItemResponseDto item) {
    addItem(ItemResponseDto(
      itemName: item.itemName,
      itemPrice: item.itemPrice,
      itemId: item.itemId,
      quantity: 1,
      type: item.type,
    ));
  }

  void onProductTypeChanged(String? value) {
    if (value != null) {
      selectedProductType.value = value;
    }
  }

  UserInfo get currentUser => userController.user.value;

  void increaseQuantity(String itemId) {
    final index = itemResponses.indexWhere((i) => i.itemId == itemId);
    if (index != -1) {
      itemResponses[index].quantity += 1;
      itemResponses.refresh();
      calculateTotalPrice();
    }
  }

  void decreaseQuantity(String itemId) {
    final index = itemResponses.indexWhere((i) => i.itemId == itemId);
    if (index != -1) {
      if (itemResponses[index].quantity > 1) {
        itemResponses[index].quantity -= 1;
        itemResponses.refresh();
      } else {
        itemResponses.removeAt(index);
      }
      calculateTotalPrice();
    }
  }

  void checkBalance() {
    final bool isChargeRequest =
        _calculationService.hasChargeItem(itemResponses);
    final bool isChargeOnly =
        _calculationService.isChargeOnlyTransaction(itemResponses);

    if (isChargeRequest) {
      final int chargeAmount = isChargeOnly
          ? totalPrice.value
          : totalPrice.value; // 혼합 결제의 경우도 전체 금액을 카드로 결제

      Get.dialog(
        AlertDialog(
          title: const Text(
            '충전 확인',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '총 금액: ${NumberFormatUtil.convert1000Number(chargeAmount)}원',
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                '카드로 충전하시겠습니까?',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('취소',
                  style: TextStyle(fontSize: 20, color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                processPayment();
              },
              child: const Text('충전 진행',
                  style: TextStyle(fontSize: 20, color: Colors.blue)),
            ),
          ],
        ),
      );
    } else {
      // 일반 상품만 있는 경우
      final expectedCardAmount = totalPrice.value > currentUser.point
          ? totalPrice.value - currentUser.point
          : 0;

      if (expectedCardAmount > 0) {
        _showPaymentConfirmDialog(expectedCardAmount);
      } else {
        processPayment();
      }
    }
  }

  void _showPaymentConfirmDialog(int cardAmount) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          '결제 확인',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '총 결제 금액: ${NumberFormatUtil.convert1000Number(totalPrice.value)}원\n'
              '사용 가능 포인트: ${NumberFormatUtil.convert1000Number(currentUser.point)}원',
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '카드 결제 예상 금액: ${NumberFormatUtil.convert1000Number(cardAmount)}원',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              '결제를 진행하시겠습니까?',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소',
                style: TextStyle(fontSize: 20, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              processPayment();
            },
            child: const Text('결제 진행',
                style: TextStyle(fontSize: 20, color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _handlePaymentException(dynamic error) {
    _logger.severe('❌ 결제 처리 중 예외 발생', error);
    Get.back(); // 진행 중 팝업 닫기

    String errorMessage = "결제 처리 중 오류가 발생했습니다.\n다시 시도해 주세요.";

    if (error is TimeoutException) {
      errorMessage = "결제 시간이 초과되었습니다.\n다시 시도해주세요.";
    } else if (error is PaymentException) {
      switch (error.code) {
        case 'INVALID_PAYMENT_REQUEST':
          errorMessage = "잘못된 결제 요청입니다.\n다시 시도해주세요.";
          break;
        case 'TRANSACTION_IN_PROGRESS':
          errorMessage = "이미 진행 중인 거래가 있습니다.\n잠시 후 다시 시도해주세요.";
          break;
        case 'PAYMENT_TIMEOUT':
          errorMessage = "결제 시간이 초과되었습니다.\n다시 시도해주세요.";
          break;
        case 'CARD_PAYMENT_FAILED':
          errorMessage = "카드 결제에 실패했습니다.\n다른 카드로 시도해주세요.";
          break;
      }
    }

    Get.dialog(
      paymentResultPopup(
        Get.context!,
        errorMessage,
        true,
      ),
      barrierDismissible: false,
    );

    Future.delayed(const Duration(seconds: 2), () {
      Get.back();
      clearItems();
      Get.offAllNamed('/');
    });
  }
}
