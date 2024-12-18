import 'package:logging/logging.dart';
import '../dto/item_response_dto.dart';
import 'payment_service.dart';

class BarcodeService {
  final PaymentService _paymentService;
  final Logger _logger = Logger('BarcodeService');

  BarcodeService(this._paymentService);

  Future<ItemResponseDto?> fetchItemData(String barcode) async {
    try {
      _logger.info('🔍 바코드 상품 조회 시작: $barcode');
      final item = await _paymentService.getItemByBarcode(barcode);

      if (item != null) {
        _logger.info(
            '📦 상품 조회 성공: ID=${item.itemId}, 이름=${item.itemName}, 가격=${item.itemPrice}원');
        return item;
      } else {
        _logger.severe('❌ 바코드에 해당하는 상품을 찾을 수 없음: $barcode');
        return null;
      }
    } catch (e) {
      _logger.severe('❌ 상품 조회 에러: $e');
      return null;
    }
  }

  bool isValidBarcode(String barcode) {
    // 바코드 유효성 검사 로직 구현
    if (barcode.isEmpty) {
      _logger.warning('⚠️ 빈 바코드 입력');
      return false;
    }

    // 추가적인 바코드 유효성 검사 규칙들...
    return true;
  }
}
