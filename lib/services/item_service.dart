import 'dart:convert';

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
  final Map<String, ItemResponse> _itemByCodeCache = {};

  ItemService(this._apiClient);

  /// 바코드로 상품 단건 조회
  /// 명세서 변경: query param → path param, 인증 불필요
  /// 구 API: GET /kiosk/item?itemCode={barcode}
  /// 신규 API: GET /items/{barcode}
  Future<ItemResponse> getItemByCode(String itemCode) async {
    final normalized = normalizeBarcode(itemCode);

    final cached = _itemByCodeCache[normalized];
    if (cached != null) {
      _logger.info('📥 [ITEM API] 바코드 캐시 사용: $normalized → ${cached.itemName}');
      return cached;
    }

    try {
      final requestJson = {
        'itemCode': normalized,
      };

      _logger.info('📤 [ITEM API] ========== 상품 조회 요청 시작 ==========');
      _logger
          .info('📤 [ITEM API] 요청 URL: ${ApiEndpoints.getItems}/$normalized');
      _logger.info('📤 [ITEM API] 요청 JSON: ${jsonEncode(requestJson)}');
      _logger.info('📤 [ITEM API] =======================================');

      // 명세서: path param 방식, /items/{barcode}
      final response = await _apiClient.get(
        '${ApiEndpoints.getItems}/$normalized',
        (json) => ItemResponse.fromJson(json as Map<String, dynamic>),
        // 명세서: /items/** 는 인증 불필요
        requiresAuth: false,
      );

      _itemByCodeCache[normalized] = response;
      _logger.info(
          '📥 [ITEM API] 응답 상품: ${response.itemName} (${response.itemCode}) 캐시 저장됨');
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

  /// 특정 바코드 상품 캐시 제거 (장바구니에서 수량 0이 된 경우)
  void removeItemFromCache(String itemCode) {
    final normalized = normalizeBarcode(itemCode);
    final removed = _itemByCodeCache.remove(normalized);
    if (removed != null) {
      _logger.info('🗑️ [ITEM API] 바코드 상품 캐시 제거: $normalized → ${removed.itemName}');
    }
  }

  /// 바코드 상품 캐시 전체 초기화
  void clearItemCache() {
    _itemByCodeCache.clear();
    _logger.info('🗑️ [ITEM API] 바코드 상품 캐시 초기화됨');
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
      _logger.info(
          '📥 [ITEM API] 바코드 없는 상품 목록 캐시 사용: ${_cachedNonBarcodeItems!.length}건');
      return _cachedNonBarcodeItems!;
    }

    try {
      const requestJson = <String, dynamic>{};

      _logger.info('📤 [ITEM API] ========== 바코드 없는 상품 조회 요청 시작 ==========');
      _logger.info('📤 [ITEM API] 요청 URL: ${ApiEndpoints.getNonBarcodeItems}');
      _logger.info('📤 [ITEM API] 요청 JSON: ${jsonEncode(requestJson)}');
      _logger.info(
          '📤 [ITEM API] ===============================================');

      final response = await _apiClient.get(
        ApiEndpoints.getNonBarcodeItems,
        (json) {
          // 명세서 변경: 배열 직접 반환 → { "items": [...] } 래핑
          return (json['items'] as List).map((item) {
            final mapped =
                NonBarcodeItemResponse.fromJson(item as Map<String, dynamic>);
            return mapped;
          }).toList();
        },
        // 명세서: /items/** 는 인증 불필요
        requiresAuth: false,
      );
      _cachedNonBarcodeItems = response;
      _logger.info('📥 [ITEM API] 바코드 없는 상품 조회 응답 건수: ${response.length}');
      return response;
    } catch (e) {
      _logger.severe('❌ 바코드 없는 상품 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 전체 상품 목록 조회
  /// 명세서: GET /items — 판매 중인 전체 상품 목록 (바코드 유무 관계없이 모든 상품)
  Future<List<ItemResponse>> getAllItems() async {
    try {
      const requestJson = <String, dynamic>{};

      _logger.info('📤 [ITEM API] ========== 전체 상품 조회 요청 시작 ==========');
      _logger.info('📤 [ITEM API] 요청 URL: ${ApiEndpoints.getItems}');
      _logger.info('📤 [ITEM API] 요청 JSON: ${jsonEncode(requestJson)}');
      _logger.info('📤 [ITEM API] ===========================================');

      final response = await _apiClient.get(
        ApiEndpoints.getItems,
        (json) {
          // 명세서: { "items": [...] } 형식으로 래핑된 응답
          return (json['items'] as List).map((item) {
            return ItemResponse.fromJson(item as Map<String, dynamic>);
          }).toList();
        },
        // 명세서: /items/** 는 인증 불필요
        requiresAuth: false,
      );
      _logger.info('📥 [ITEM API] 전체 상품 조회 응답 건수: ${response.length}');
      return response;
    } catch (e) {
      _logger.severe('❌ 전체 상품 목록 조회 실패: $e');
      rethrow;
    }
  }
}
