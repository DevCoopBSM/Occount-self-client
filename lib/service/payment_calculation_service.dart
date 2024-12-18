import 'package:logging/logging.dart';
import '../dto/item_response_dto.dart';
import '../models/payment_response.dart';
import '../ui/_constant/util/number_format_util.dart';

class PaymentCalculationService {
  final Logger _logger = Logger('PaymentCalculationService');

  int calculateTotalAmount(List<ItemResponseDto> items) {
    return items.fold<int>(
        0, (sum, item) => sum + (item.itemPrice * item.quantity));
  }

  int calculateChargeAmount(List<ItemResponseDto> items) {
    return items
        .where((item) => item.type == 'CHARGE')
        .fold<int>(0, (sum, item) => sum + (item.itemPrice * item.quantity));
  }

  int calculateCardAmount({
    required List<ItemResponseDto> items,
    required int totalPrice,
    required int currentPoints,
  }) {
    final isChargeRequest = hasChargeItem(items);

    // 충전 요청이 포함된 경우 전체 금액을 카드로 결제
    if (isChargeRequest) {
      _logger.info('💳 충전 포함 결제: 전체 금액 카드 결제 - $totalPrice원');
      return totalPrice;
    }

    // 일반 상품만 있는 경우 포인트 사용 후 남은 금액만 카드 결제
    final cardAmount =
        totalPrice > currentPoints ? totalPrice - currentPoints : 0;

    _logger.info('💳 일반 결제 - 카드: $cardAmount원');
    return cardAmount;
  }

  String buildResultMessage({
    required PaymentResponse response,
    required List<ItemResponseDto> items,
    required bool isChargeRequest,
    required bool isChargeOnly,
    required int totalPrice,
    required int currentPoints,
  }) {
    if (isChargeOnly) {
      return "충전금액: ${NumberFormatUtil.convert1000Number(response.chargedAmount)}원\n"
          "잔여금액: ${NumberFormatUtil.convert1000Number(response.balanceAfterCharge)}원\n"
          "승인번호: ${response.approvalNumber}";
    }

    if (isChargeRequest) {
      final chargeAmount = calculateChargeAmount(items);
      final paymentAmount = totalPrice - chargeAmount;
      final cardPaymentAmount =
          paymentAmount > currentPoints ? paymentAmount - currentPoints : 0;

      return "충전금액: ${NumberFormatUtil.convert1000Number(chargeAmount)}원\n"
          "결제금액: ${NumberFormatUtil.convert1000Number(paymentAmount)}원\n"
          "${cardPaymentAmount > 0 ? "카드결제: ${NumberFormatUtil.convert1000Number(cardPaymentAmount)}원\n" : ""}"
          "잔여금액: ${NumberFormatUtil.convert1000Number(response.remainingPoints)}원\n"
          "승인번호: ${response.approvalNumber}";
    }

    final cardAmount =
        totalPrice > currentPoints ? totalPrice - currentPoints : 0;

    return "결제금액: ${NumberFormatUtil.convert1000Number(response.totalAmount)}원\n"
        "${cardAmount > 0 ? "카드결제: ${NumberFormatUtil.convert1000Number(cardAmount)}원\n" : ""}"
        "잔여금액: ${NumberFormatUtil.convert1000Number(response.remainingPoints)}원\n"
        "${response.approvalNumber.isNotEmpty ? "승인번호: ${response.approvalNumber}" : ""}";
  }

  bool isChargeOnlyTransaction(List<ItemResponseDto> items) {
    return items.every((item) => item.type == 'CHARGE');
  }

  bool hasChargeItem(List<ItemResponseDto> items) {
    return items.any((item) => item.type == 'CHARGE');
  }
}
