import 'package:logging/logging.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/item_response.dart';
import '../models/payment_response.dart';
import '../exception/payment_exception.dart';
import '../exception/api_exception.dart';
import '../models/payment_request.dart';
import '../models/order_request.dart';
import '../models/cart_item.dart';
import 'dart:convert';

class PaymentService {
  final ApiClient _apiClient;
  final Logger _logger = Logger('PaymentService');
  List<ItemResponse>? _cachedItems;

  PaymentService(this._apiClient);

  Future<ItemResponse> getItemByCode(String itemCode) async {
    try {
      _logger.info('📤 상품 조회 요청 - 바코드: $itemCode');

      // 명세서 변경: path param 방식, /items/{barcode}
      final response = await _apiClient.get(
        '${ApiEndpoints.getItems}/$itemCode',
        (json) {
          _logger.info('📥 API 응답 원본: $json');
          final item = ItemResponse.fromJson(json as Map<String, dynamic>);
          _logger.info('''
📦 조회된 상품 정보:
- 상품ID: ${item.itemId}
- 바코드: ${item.itemCode}
- 상품명: ${item.itemName}
- 가격: ${item.itemPrice}원
- 카테고리: ${item.itemCategory}
''');
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

  /// 결제 실행 (주문 생성 → 결제 순서)
  ///
  /// 명세서 변경:
  /// 1. 결제 전 POST /orders 로 주문 먼저 생성 (신규)
  /// 2. userCode, userName 파라미터 제거 (토큰 기반 인증)
  /// 3. userPoint로 결제 타입 결정 (PAYMENT vs MIXED)
  /// 4. CHARGE 타입 및 충전 로직 제거
  /// 5. 요청 body에서 userInfo, charge 필드 제거
  Future<PaymentResponse> executePayment({
    required List<CartItem> items,
    // 명세서: 포인트 잔액으로 PAYMENT(포인트 단독) vs MIXED(포인트+카드) 결정
    required int userPoint,
  }) async {
    try {
      _logger.info('💰 결제 API 요청 시작');

      // 결제 총액 계산
      final totalAmount = items.fold<int>(
          0, (sum, item) => sum + (item.itemPrice * item.quantity));

      // 명세서: 포인트 ≥ 총액이면 PAYMENT, 부족하면 MIXED
      final paymentType =
          totalAmount <= userPoint ? PaymentType.PAYMENT : PaymentType.MIXED;

      _logger.info('💫 결제 타입: $paymentType (총액: $totalAmount, 보유포인트: $userPoint)');

      // Step 1: 주문 생성 (명세서 신규 — 결제 전 필수)
      _logger.info('📋 Step 1: 주문 생성 시작');
      final orderRequest = OrderRequest(
        orderInfos: items
            .map((item) => OrderItem(
                  itemId: item.itemId,
                  orderQuantity: item.quantity,
                ))
            .toList(),
      );

      await _apiClient.post(
        ApiEndpoints.createOrder,
        orderRequest.toJson(),
        // POST /orders 성공 시 응답 body 없음(200 OK)
        (json) => json,
        requiresAuth: true,
      );
      _logger.info('✅ Step 1 완료: 주문 생성 성공');

      // Step 2: 결제 실행
      _logger.info('💳 Step 2: 결제 실행 시작');

      final paymentItems =
          items.map((item) => PaymentItem.fromCartItem(item)).toList();

      // 명세서: userInfo, charge 필드 없음 — type + payment만 전송
      final request = PaymentRequest(
        type: paymentType,
        payment: PaymentInfo(
          items: paymentItems,
          totalAmount: totalAmount,
        ),
      );

      _logger.info('📡 결제 요청 데이터: ${jsonEncode(request.toJson())}');

      return await _apiClient.post(
        ApiEndpoints.executePayment,
        request.toJson(),
        (json) {
          final response = PaymentResponse.fromJson(json as Map<String, dynamic>);
          if (!response.success) {
            throw PaymentException(
              code: 'PAYMENT_FAILED',
              message: response.message,
              status: 500,
            );
          }
          return response;
        },
        requiresAuth: true,
      );
    } catch (e) {
      _logger.severe('❌ 결제 실패: $e');

      if (e is ApiException) rethrow;
      if (e is PaymentException) rethrow;

      throw ApiException.fromErrorCode(
        ApiErrorCode.serverError,
        '결제 처리 중 오류가 발생했습니다',
      );
    }
  }
}
