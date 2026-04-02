import 'package:logging/logging.dart';
import '../models/item_response.dart';
import '../models/non_barcode_item_response.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../exception/api_exception.dart';

class ItemService {
  final ApiClient _apiClient;
  final Logger _logger = Logger('ItemService');
  List<NonBarcodeItemResponse>? _cachedNonBarcodeItems;

  ItemService(this._apiClient);

  /// 바코드로 상품 단건 조회
  /// 명세서 변경: query param → path param, 인증 불필요
  /// 구 API: GET /kiosk/item?itemCode={barcode}
  /// 신규 API: GET /items/{barcode}
  Future<ItemResponse> getItemByCode(String itemCode) async {
    try {
      _logger.info('🔍 바코드 상품 조회 시작: $itemCode');
      // 명세서: path param 방식, /items/{barcode}
      final response = await _apiClient.get(
        '${ApiEndpoints.getItems}/$itemCode',
        (json) => ItemResponse.fromJson(json as Map<String, dynamic>),
        // 명세서: /items/** 는 인증 불필요
        requiresAuth: false,
      );
      _logger.info('📦 상품 조회 성공: ${response.itemName}');
      return response;
    } catch (e) {
      _logger.severe('❌ 상품 조회 실패: $e');
      throw ApiException(
        code: ApiErrorCode.itemNotFound,
        message: '상품을 찾을 수 없습니다.',
        status: '404',
      );
    }
  }

  String normalizeBarcode(String barcode) {
    return barcode.trim().replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// 바코드 없는 상품 목록 조회
  /// 명세서 변경: 응답 형식 변경 — json['items'] 래핑, 인증 불필요
  /// 구 API: GET /kiosk/items/no-barcode → 배열 직접 반환
  /// 신규 API: GET /items/without-barcode → { "items": [...] }
  Future<List<NonBarcodeItemResponse>> getNonBarcodeItems() async {
    if (_cachedNonBarcodeItems != null) {
      _logger.info('📦 캐시된 바코드 없는 상품 목록 반환');
      return _cachedNonBarcodeItems!;
    }

    try {
      _logger.info('🔍 바코드 없는 상품 목록 조회 시작');
      final response = await _apiClient.get(
        ApiEndpoints.getNonBarcodeItems,
        (json) {
          _logger.info('API 응답: $json');
          // 명세서 변경: 배열 직접 반환 → { "items": [...] } 래핑
          return (json['items'] as List).map((item) {
            final mapped = NonBarcodeItemResponse.fromJson(item as Map<String, dynamic>);
            _logger.info('변환된 아이템: itemId=${mapped.itemId}, name=${mapped.itemName}');
            return mapped;
          }).toList();
        },
        // 명세서: /items/** 는 인증 불필요
        requiresAuth: false,
      );
      _cachedNonBarcodeItems = response;
      return response;
    } catch (e) {
      _logger.severe('❌ 바코드 없는 상품 목록 조회 실패: $e');
      rethrow;
    }
  }
}
