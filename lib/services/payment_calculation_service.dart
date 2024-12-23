import 'package:logging/logging.dart';
import '../models/cart_item.dart';
import '../models/payment_response.dart';
import '../ui/_constant/util/number_format_util.dart';

class PaymentCalculationService {
  final Logger _logger = Logger('PaymentCalculationService');

  int calculateTotalAmount(List<CartItem> items) {
    return items.fold<int>(0, (sum, item) => sum + item.totalPrice);
  }

  int calculateChargeAmount(List<CartItem> items) {
    return items
        .where((item) => item.itemCategory == 'CHARGE')
        .fold<int>(0, (sum, item) => sum + item.totalPrice);
  }

  int calculateCardAmount({
    required List<CartItem> items,
    required int totalPrice,
    required int currentPoints,
  }) {
    if (isChargeOnlyTransaction(items)) {
      return totalPrice;
    }
    return totalPrice > currentPoints ? totalPrice - currentPoints : 0;
  }

  String buildResultMessage({
    required PaymentResponse response,
    required List<CartItem> items,
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

  bool isChargeOnlyTransaction(List<CartItem> items) {
    return items.every((item) => item.itemCategory == 'CHARGE');
  }

  bool hasChargeItem(List<CartItem> items) {
    return items.any((item) => item.itemCategory == 'CHARGE');
  }
}
