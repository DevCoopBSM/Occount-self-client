import '../models/cart_item.dart';
import 'package:logging/logging.dart';

class ChargeService {
  final Logger _logger = Logger('ChargeService');

  static const String chargeItemId = "ARIPAY_CHARGE";
  static const String chargeItemType = "CHARGE";
  static const String chargeItemName = "아리페이 충전";

  CartItem createChargeItem(int amount) {
    if (amount <= 0) {
      throw ArgumentError('충전 금액은 0보다 커야 합니다.');
    }

    _logger.info('💰 충전 아이템 생성: $amount원');

    return CartItem(
      itemId: -1,
      itemCode: chargeItemId,
      itemName: chargeItemName,
      quantity: 1,
      itemPrice: amount,
      itemCategory: chargeItemType,
    );
  }

  int calculateTotalChargeAmount(List<CartItem> items) {
    return items
        .where((item) => item.itemCategory == chargeItemType)
        .fold<int>(0, (sum, item) => sum + item.totalPrice);
  }

  bool isValidChargeAmount(int amount) {
    if (amount <= 0) {
      _logger.warning('⚠️ 잘못된 충전 금액: $amount원');
      return false;
    }
    return true;
  }
}
