import 'package:logging/logging.dart';
import '../models/item_response.dart';
import '../models/top_item_response.dart';
import '../models/non_barcode_item_response.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../exception/api_exception.dart';

class ItemService {
  final ApiClient _apiClient;
  final Logger _logger = Logger('ItemService');
  List<NonBarcodeItemResponse>? _cachedNonBarcodeItems;

  ItemService(this._apiClient);

  Future<ItemResponse> getItemByCode(String itemCode) async {
    try {
      _logger.info('🔍 바코드 상품 조회 시작: $itemCode');
      final queryParams = {'itemCode': itemCode};
      final response = await _apiClient.get(
        ApiEndpoints.getItem,
        (json) {
          if (json is List && json.isNotEmpty) {
            return ItemResponse.fromJson(json[0] as Map<String, dynamic>);
          }
          throw ApiException(
            code: ApiErrorCode.notFound,
            message: '상품을 찾을 수 없습니다.',
            status: '404',
          );
        },
        queryParams: queryParams,
      );
      _logger.info('📦 상품 조회 성공: ${response.itemName}');
      return response;
    } catch (e) {
      _logger.severe('❌ 상품 조회 실패: $e');
      throw ApiException(
        code: ApiErrorCode.notFound,
        message: '상품을 찾을 수 없습니다.',
        status: '404',
      );
    }
  }

  String normalizeBarcode(String barcode) {
    return barcode.trim().replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<List<TopItemResponse>> getTopItems() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.getTopItems,
        (json) => (json as List)
            .map((item) => TopItemResponse.fromJson(item))
            .toList(),
      );
      return response;
    } catch (e) {
      _logger.severe('❌ 인기 상품 조회 실패: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

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
          return (json as List).map((item) {
            final mapped = NonBarcodeItemResponse.fromJson(item);
            _logger.info(
                '변환된 아이템: itemId=${mapped.itemId}, name=${mapped.itemName}');
            return mapped;
          }).toList();
        },
      );
      _cachedNonBarcodeItems = response;
      return response;
    } catch (e) {
      _logger.severe('❌ 바코드 없는 상품 목록 조회 실패: $e');
      rethrow;
    }
  }
}
