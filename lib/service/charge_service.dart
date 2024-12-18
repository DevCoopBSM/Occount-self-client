import '../dto/item_response_dto.dart';
import 'package:logging/logging.dart';

class ChargeService {
  final Logger _logger = Logger('ChargeService');

  static const String CHARGE_ITEM_ID = "ARIPAY_CHARGE";
  static const String CHARGE_ITEM_TYPE = "CHARGE";
  static const String CHARGE_ITEM_NAME = "아리페이 충전";

  ItemResponseDto createChargeItem(int amount) {
    if (amount <= 0) {
      throw ArgumentError('충전 금액은 0보다 커야 합니다.');
    }

    _logger.info('💰 충전 아이템 생성: $amount원');

    return ItemResponseDto(
        itemName: CHARGE_ITEM_NAME,
        itemPrice: amount,
        itemId: CHARGE_ITEM_ID,
        quantity: 1,
        type: CHARGE_ITEM_TYPE);
  }

  bool isValidChargeAmount(int amount) {
    if (amount <= 0) {
      _logger.warning('⚠️ 잘못된 충전 금액: $amount원');
      return false;
    }

    // 추가적인 충전 금액 유효성 검사 규칙들...
    return true;
  }

  int calculateTotalChargeAmount(List<ItemResponseDto> items) {
    return items
        .where((item) => item.type == CHARGE_ITEM_TYPE)
        .fold<int>(0, (sum, item) => sum + (item.itemPrice * item.quantity));
  }
}
