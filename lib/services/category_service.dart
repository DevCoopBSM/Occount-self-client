import 'package:logging/logging.dart';

import '../api/api_endpoints.dart';
import '../api/api_client.dart';
import '../models/non_barcode_item_response.dart';
import '../exception/api_exception.dart';

class CategoryService {
  final ApiClient _apiClient;
  final Logger _logger = Logger('CategoryService');
  List<NonBarcodeItemResponse>? _cachedItems;
  List<String>? _cachedCategories;

  CategoryService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<NonBarcodeItemResponse>> getNonBarcodeItems() async {
    if (_cachedItems != null) {
      return _cachedItems!;
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.getNonBarcodeItems,
        (json) => (json as List)
            .map((item) => NonBarcodeItemResponse.fromJson(item))
            .toList(),
      );
      _cachedItems = response;
      return response;
    } catch (e) {
      _logger.warning('❌ 바코드 없는 상품 목록 조회 실패: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  Future<List<String>> getCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      final items = await getNonBarcodeItems();
      final categories = items
          .map((item) => item.itemCategory)
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList();

      _cachedCategories = categories;
      _logger.info('📑 카테고리 목록 조회 성공: $categories');
      return categories;
    } catch (e) {
      _logger.warning('❌ 카테고리 목록 조회 실패: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  Future<List<NonBarcodeItemResponse>> getItemsByCategory(
      String category) async {
    try {
      final allItems = _cachedItems ?? await getNonBarcodeItems();
      return allItems.where((item) => item.itemCategory == category).toList();
    } catch (e) {
      _logger.warning('❌ 카테고리별 상품 조회 실패: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }
}
