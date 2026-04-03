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
      // 명세서: path param 방식, /items/{barcode}
      final response = await _apiClient.get(
        '${ApiEndpoints.getItems}/$itemCode',
        (json) => ItemResponse.fromJson(json as Map<String, dynamic>),
        // 명세서: /items/** 는 인증 불필요
        requiresAuth: false,
      );
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
      return _cachedNonBarcodeItems!;
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.getNonBarcodeItems,
        (json) {
          // 명세서 변경: 배열 직접 반환 → { "items": [...] } 래핑
          return (json['items'] as List).map((item) {
            final mapped = NonBarcodeItemResponse.fromJson(item as Map<String, dynamic>);
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
