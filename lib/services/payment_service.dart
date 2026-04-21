import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/item_response.dart';
import '../models/order_status_response.dart';
import '../models/payment_response.dart';
import '../exception/payment_exception.dart';
import '../exception/api_exception.dart';
import '../models/order_request.dart';
import '../models/cart_item.dart';
import 'kiosk_config_service.dart';

class PaymentService {
  static const Duration orderPollingInterval = Duration(seconds: 1);
  static const Duration orderPollingTimeout = Duration(seconds: 30);
  static const Duration initialOrderPollingDelay = Duration(seconds: 1);

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

  Future<OrderStatusResponse> createOrder({
    required List<CartItem> items,
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

      // 명세서: kioskId는 요청 본문 필수값
      final kioskId = await _kioskConfigService.getKioskId();
      if (kioskId == null || kioskId.isEmpty) {
        throw PaymentException(
          code: 'KIOSK_ID_MISSING',
          message: '키오스크 ID가 설정되지 않았습니다.',
          status: 400,
        );
      }
      _logger.info('🏪 [ORDER API] 키오스크 ID: $kioskId');

      // 주문 생성
      final totalAmount = items.fold<int>(
        0,
        (sum, item) => sum + (item.itemPrice * item.quantity),
      );
      final orderRequest = OrderRequest(
        orderInfos: items
            .map((item) => OrderItem(
                  itemId: item.itemId,
                  itemName: item.itemName,
                  itemPrice: item.itemPrice,
                  quantity: item.quantity,
                ))
            .toList(),
        totalAmount: totalAmount,
        kioskId: kioskId,
      );

      // 🔍 디버깅: 요청 내용 상세 로그
      final requestBody = orderRequest.toJson();
      _logger.info('📤 [ORDER API] ========== 주문 요청 시작 ==========');
      _logger.info('📤 [ORDER API] 요청 URL: ${ApiEndpoints.createOrder}');
      _logger.info('📤 [ORDER API] 키오스크 ID: $kioskId');
      _logger.info('📤 [ORDER API] 게스트 모드: $isGuestMode');
      _logger.info('📤 [ORDER API] 인증 필요: ${!isGuestMode}');
      _logger.info('📤 [ORDER API] 전체 요청 Body: $requestBody');
      _logger.info('📤 [ORDER API] 상품 개수: ${items.length}');

      // 각 상품 상세 정보
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        _logger.info(
            '📤 [ORDER API] 상품[$i]: ID=${item.itemId}, 코드="${item.itemCode}", 이름="${item.itemName}", 수량=${item.quantity}, 가격=${item.itemPrice}, 카테고리="${item.itemCategory}"');
      }

      _logger.info('📤 [ORDER API] 총 주문 금액: $totalAmount원');
      _logger.info('📤 [ORDER API] ========================================');

      final response = await _apiClient.post<OrderStatusResponse>(
        ApiEndpoints.createOrder,
        orderRequest.toJson(),
        (json) {
          _logger.info('📥 [ORDER API] ========== 주문 응답 수신 ==========');
          _logger.info('📥 [ORDER API] 응답 성공');
          _logger.info('📥 [ORDER API] 응답 Body: ${json ?? "NULL/EMPTY"}');
          _logger.info('📥 [ORDER API] 응답 타입: ${json.runtimeType}');
          _logger.info('📥 [ORDER API] ======================================');
          return OrderStatusResponse.fromJson(json as Map<String, dynamic>);
        },
        requiresAuth: !isGuestMode,
        includeKioskId: true,
        successStatusCodes: const [202],
      );

      _logger.info(
          '✅ [ORDER API] 생성 완료 - orderId: ${response.orderId}, status: ${response.status}');
      return response;
    } catch (e) {
      // 🔍 디버깅: 에러 상세 정보 로그
      _logger.severe('❌ 주문 생성 실패: $e');
      _logger.severe('❌ 에러 타입: ${e.runtimeType}');
      if (e is ApiException) {
        _logger.severe(
            '❌ [ApiException] 코드: ${e.code.code}, 메시지: ${e.message}, HTTP상태: ${e.code.statusCode}');
      }
      if (e is PaymentException) {
        _logger.severe(
            '❌ [PaymentException] 코드: ${e.code}, 메시지: ${e.message}, 상태: ${e.status}');
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

  Future<OrderStatusResponse> getOrderStatus(String orderId) async {
    try {
      return await _apiClient.get<OrderStatusResponse>(
        ApiEndpoints.getOrderStatus(orderId),
        (json) => OrderStatusResponse.fromJson(json as Map<String, dynamic>),
        requiresAuth: false,
        includeKioskId: true,
      );
    } catch (e) {
      _logger.severe('❌ 주문 상태 조회 실패: $e');
      rethrow;
    }
  }

  Future<OrderStatusResponse> pollOrderStatusUntilFinal(
    String orderId, {
    Duration interval = orderPollingInterval,
    Duration timeout = orderPollingTimeout,
    Duration initialDelay = Duration.zero,
  }) async {
    if (initialDelay > Duration.zero) {
      _logger.info('⏳ 첫 주문 상태 조회 대기 - orderId: $orderId, delay: $initialDelay');
      await Future.delayed(initialDelay);
    }

    final deadline = DateTime.now().add(timeout);
    var currentStatus = await getOrderStatus(orderId);

    while (!currentStatus.isTerminal) {
      if (DateTime.now().isAfter(deadline)) {
        _logger.warning('⏱️ 주문 상태 폴링 타임아웃 - orderId: $orderId');
        return OrderStatusResponse(
          orderId: orderId,
          status: OrderStatus.timedOut,
        );
      }

      _logger.info(
          '🔄 주문 상태 폴링 - orderId: $orderId, status: ${currentStatus.status}');
      await Future.delayed(interval);
      currentStatus = await getOrderStatus(orderId);
    }

    _logger.info(
        '✅ 주문 상태 최종 확인 - orderId: $orderId, status: ${currentStatus.status}');
    return currentStatus;
  }

  Future<OrderStatusResponse> cancelOrder({
    required String orderId,
    bool isGuestMode = false,
  }) async {
    try {
      return await _apiClient.post<OrderStatusResponse>(
        ApiEndpoints.cancelOrder(orderId),
        null,
        (json) => OrderStatusResponse.fromJson(json as Map<String, dynamic>),
        requiresAuth: !isGuestMode,
        includeKioskId: true,
      );
    } catch (e) {
      _logger.severe('❌ 주문 취소 요청 실패: $e');
      rethrow;
    }
  }

  Future<PaymentResponse> executePayment({
    required List<CartItem> items,
    required int userPoint,
    bool isGuestMode = false,
  }) async {
    final createdOrder = await createOrder(
      items: items,
      isGuestMode: isGuestMode,
    );
    final finalStatus = await pollOrderStatusUntilFinal(
      createdOrder.orderId,
      initialDelay: initialOrderPollingDelay,
    );

    if (finalStatus.status != OrderStatus.completed) {
      throw ApiException.fromErrorCode(
        ApiErrorCode.paymentFailed,
        '결제 처리에 실패했습니다',
      );
    }

    return PaymentResponse(
      success: true,
      message: '주문이 정상처리되었습니다',
      totalAmount: items.fold<int>(0, (sum, item) => sum + item.totalPrice),
      remainingPoints: userPoint,
    );
  }
}
