import 'package:logging/logging.dart';

import '../api/api_endpoints.dart';
import '../api/api_client.dart';
import '../models/non_barcode_item_response.dart';
import '../exception/api_exception.dart';

class CategoryService {
  final ApiClient _apiClient;
  final Logger _logger = Logger('CategoryService');
  // 명세서 변경: /items/without-barcode에는 category 없음
  // → category가 있는 /items (전체 목록)를 캐시로 사용
  List<NonBarcodeItemResponse>? _cachedItems;
  List<String>? _cachedCategories;

  CategoryService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// 전체 상품 목록을 조회하고 캐싱 (category 필드 포함)
  /// 명세서 변경: /items/without-barcode에는 category가 없으므로
  ///             category 필터링을 위해 /items (전체 목록) 사용
  Future<List<NonBarcodeItemResponse>> getNonBarcodeItems() async {
    if (_cachedItems != null) {
      return _cachedItems!;
    }

    try {
      // 명세서: GET /items — category 필드 포함된 전체 상품 목록
      // NonBarcodeItemResponse는 itemId, name, price, category를 공유하므로 재사용 가능
      final response = await _apiClient.get(
        ApiEndpoints.getItems,
        (json) => (json['items'] as List)
            .map((item) => NonBarcodeItemResponse.fromJson(item as Map<String, dynamic>))
            .toList(),
        // 명세서: /items/** 는 인증 불필요
        requiresAuth: false,
      );
      _cachedItems = response;
      return response;
    } catch (e) {
      _logger.warning('❌ 상품 목록 조회 실패: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  /// 카테고리 목록 조회
  /// 명세서 변경: 아이템에서 파생하지 않고 전용 엔드포인트 사용
  /// 구 방식: 아이템 목록에서 itemCategory 추출
  /// 신규: GET /items/categories → { "itemCategories": ["BEVERAGE", "FOOD", ...] }
  Future<List<String>> getCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      final categories = await _apiClient.get(
        ApiEndpoints.getItemCategories,
        (json) {
          // 명세서 응답: { "item_categories": ["BEVERAGE", "FOOD", "SNACK"] }
          return (json['item_categories'] as List).cast<String>();
        },
        requiresAuth: false,
      );

      _cachedCategories = categories;
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
