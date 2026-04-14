import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/item_response.dart';
import '../models/payment_response.dart';
import '../exception/payment_exception.dart';
import '../exception/api_exception.dart';
import '../models/order_request.dart';
import '../models/cart_item.dart';
import 'kiosk_config_service.dart';

class PaymentService {
  final ApiClient _apiClient;
  final KioskConfigService _kioskConfigService;
  final Logger _logger = Logger('PaymentService');
  List<ItemResponse>? _cachedItems;

  PaymentService(this._apiClient, this._kioskConfigService);

  Future<ItemResponse> getItemByCode(String itemCode) async {
    try {
      // 명세서 변경: path param 방식, /items/{barcode}
      final response = await _apiClient.get(
        '${ApiEndpoints.getItems}/$itemCode',
        (json) {
          final item = ItemResponse.fromJson(json as Map<String, dynamic>);
          return item;
        },
        // 명세서: /items/** 인증 불필요
        requiresAuth: false,
      );

      return response;
    } catch (e) {
      _logger.severe('❌ 상품 조회 실패: $e');
      throw PaymentException(
        code: 'ITEM_NOT_FOUND',
        message: '상품을 찾을 수 없습니다.',
        status: 404,
      );
    }
  }

  Future<List<ItemResponse>> getNonBarcodeItems() async {
    if (_cachedItems != null) {
      return _cachedItems!;
    }

    try {
      // 명세서 변경: 응답이 { "items": [...] } 래핑 구조
      final response = await _apiClient.get(
        ApiEndpoints.getNonBarcodeItems,
        (json) => (json['items'] as List)
            .map((item) => ItemResponse.fromJson(item as Map<String, dynamic>))
            .toList(),
        requiresAuth: false,
      );
      _cachedItems = response;
      return response;
    } catch (e) {
      _logger.severe('바코드 없는 상품 목록 조회 실패: $e');
      throw PaymentException(
        code: 'FETCH_ITEMS_FAILED',
        message: '상품 목록을 가져오는데 실패했습니다.',
        status: 500,
      );
    }
  }

  /// 주문 생성 (order API만 호출)
  ///
  /// 명세서 변경:
  /// 1. POST /orders 로 주문 생성만 수행
  /// 2. userCode, userName 파라미터 제거 (토큰 기반 인증)
  /// 3. 성공 시 주문 완료로 처리
  /// 4. 게스트 모드에서는 인증 없이 주문 생성
  Future<PaymentResponse> executePayment({
    required List<CartItem> items,
    required int userPoint,
    bool isGuestMode = false,
  }) async {
    try {
      _logger.info('💰 주문 생성 API 요청 시작');

      // 🔍 디버깅: 토큰 확인 (게스트 모드가 아닌 경우에만)
      if (!isGuestMode) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        _logger.info('🔑 [ORDER API] 저장된 전체 토큰: $token');
      } else {
        _logger.info('👤 [ORDER API] 게스트 모드로 주문 생성');
      }

      // 키오스크 ID 조회
      final kioskId = await _kioskConfigService.getKioskId();
      _logger.info('🏪 [ORDER API] 키오스크 ID: $kioskId');

      // 주문 생성
      final orderRequest = OrderRequest(
        orderInfos: items
            .map((item) => OrderItem(
                  itemId: item.itemId,
                  orderQuantity: item.quantity,
                ))
            .toList(),
        kioskId: kioskId,
      );

      // 🔍 디버깅: 요청 내용 상세 로그
      final requestBody = orderRequest.toJson();
      _logger.info('📤 [ORDER API] ========== 주문 요청 시작 ==========');
      _logger.info('📤 [ORDER API] 요청 URL: ${ApiEndpoints.createOrder}');
      _logger.info('📤 [ORDER API] 키오스크 ID: ${kioskId ?? "NULL"}');
      _logger.info('📤 [ORDER API] 게스트 모드: $isGuestMode');
      _logger.info('📤 [ORDER API] 인증 필요: ${!isGuestMode}');
      _logger.info('📤 [ORDER API] 전체 요청 Body: $requestBody');
      _logger.info('📤 [ORDER API] 상품 개수: ${items.length}');

      // 각 상품 상세 정보
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        _logger.info('📤 [ORDER API] 상품[$i]: ID=${item.itemId}, 코드="${item.itemCode}", 이름="${item.itemName}", 수량=${item.quantity}, 가격=${item.itemPrice}, 카테고리="${item.itemCategory}"');
      }

      // 총 금액 계산
      final totalAmount = items.fold<int>(0, (sum, item) => sum + (item.itemPrice * item.quantity));
      _logger.info('📤 [ORDER API] 총 주문 금액: $totalAmount원');
      _logger.info('📤 [ORDER API] ========================================');

      final response = await _apiClient.post(
        ApiEndpoints.createOrder,
        orderRequest.toJson(),
        // POST /orders 성공 시 응답 body 없음(200 OK)
        (json) {
          // 🔍 디버깅: 응답 내용 상세 로그
          _logger.info('📥 [ORDER API] ========== 주문 응답 수신 ==========');
          _logger.info('📥 [ORDER API] 응답 성공 (HTTP 200 OK)');
          _logger.info('📥 [ORDER API] 응답 Body: ${json ?? "NULL/EMPTY"}');
          _logger.info('📥 [ORDER API] 응답 타입: ${json.runtimeType}');
          _logger.info('📥 [ORDER API] ======================================');
          return json ?? {}; // 빈 응답 처리
        },
        requiresAuth: !isGuestMode,
      );

      // 🔍 디버깅: 최종 처리 결과 로그
      _logger.info('✅ [ORDER API] ========== 주문 처리 완료 ==========');
      _logger.info('✅ [ORDER API] 최종 응답 데이터: $response');
      _logger.info('✅ [ORDER API] 주문이 정상적으로 처리되었습니다');
      _logger.info('✅ [ORDER API] 키오스크 ID "${kioskId ?? "NULL"}"로 주문 전송 완료');
      _logger.info('✅ [ORDER API] =====================================');

      // 성공 응답 생성
      return PaymentResponse(
        success: true,
        message: '주문이 정상처리되었습니다',
        totalAmount: items.fold<int>(
          0, (sum, item) => sum + (item.itemPrice * item.quantity)
        ),
        remainingPoints: userPoint,
      );
    } catch (e) {
      // 🔍 디버깅: 에러 상세 정보 로그
      _logger.severe('❌ 주문 생성 실패: $e');
      _logger.severe('❌ 에러 타입: ${e.runtimeType}');
      if (e is ApiException) {
        _logger.severe('❌ [ApiException] 코드: ${e.code.code}, 메시지: ${e.message}, HTTP상태: ${e.code.statusCode}');
      }
      if (e is PaymentException) {
        _logger.severe('❌ [PaymentException] 코드: ${e.code}, 메시지: ${e.message}, 상태: ${e.status}');
      }
      _logger.severe('❌ 스택 트레이스: ${StackTrace.current}');

      if (e is ApiException) rethrow;
      if (e is PaymentException) rethrow;

      throw ApiException.fromErrorCode(
        ApiErrorCode.serverError,
        '주문 처리 중 오류가 발생했습니다',
      );
    }
  }
}
