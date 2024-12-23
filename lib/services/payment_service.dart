import 'package:logging/logging.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/item_response.dart';
import '../models/payment_response.dart';
import '../exception/payment_exception.dart';
import '../models/payment_request.dart';
import '../models/cart_item.dart';

class PaymentService {
  final ApiClient _apiClient;
  final Logger _logger = Logger('PaymentService');
  List<ItemResponse>? _cachedItems;

  PaymentService(this._apiClient);

  Future<ItemResponse> getItemByCode(String itemCode) async {
    try {
      _logger.info('📤 상품 조회 요청 - 바코드: $itemCode');

      final response = await _apiClient.get(
        '${ApiEndpoints.getItem}/$itemCode',
        (json) {
          _logger.info('📥 API 응답 원본: $json');
          final item = ItemResponse.fromJson(json);
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
      );

      // 바코드 일치 여부 확인
      if (response.itemCode != itemCode) {
        _logger.warning('⚠️ 바코드 불일치! 요청: $itemCode, 응답: ${response.itemCode}');
        throw PaymentException(
          code: 'ITEM_MISMATCH',
          message: '잘못된 상품이 조회되었습니다.',
          status: 400,
        );
      }

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
      final response = await _apiClient.get(
        ApiEndpoints.getNonBarcodeItems,
        (json) =>
            (json as List).map((item) => ItemResponse.fromJson(item)).toList(),
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

  Future<PaymentResponse> executePayment({
    required List<CartItem> items,
    required String userCode,
    required String userName,
    required int totalPrice,
  }) async {
    try {
      final request = PaymentRequest(
        type: 'PAYMENT',
        userInfo: UserInfo(id: userCode),
        payment: PaymentInfo(
          items: items.map((item) => PaymentItem.fromCartItem(item)).toList(),
          totalAmount: totalPrice,
        ),
      );

      _logger.info('💰 결제 요청 시작');
      _logger.info('사용자: $userName ($userCode)');
      _logger.info('총 결제금액: $totalPrice원');
      _logger.info('상품 목록:');
      for (var item in items) {
        _logger
            .info('- ${item.itemName}: ${item.quantity}개, ${item.totalPrice}원');
      }
      _logger.info('요청 데이터: ${request.toJson()}');

      try {
        final response = await _apiClient
            .post(
          ApiEndpoints.executePayment,
          request.toJson(),
          (json) => PaymentResponse.fromJson(json),
        )
            .timeout(
          const Duration(seconds: 31),
          onTimeout: () {
            _logger.warning('⚠️ 결제 요청 타임아웃 (31초 초과)');
            throw PaymentException(
              code: 'PAYMENT_TIMEOUT',
              message: '결제 처리 시간이 초과되었습니다.\n잠시 후 다시 시도해주세요.',
              status: 408,
            );
          },
        );

        _logger.info('✅ 결제 성공');
        _logger.info('응답 데이터: ${response.toJson()}');
        return response;
      } catch (e) {
        _logger.severe('❌ 결제 처리 중 오류: $e');
        if (e is PaymentException) {
          rethrow;
        }
        final errorResponse = e as dynamic;
        final errorMessage =
            errorResponse?.message ?? '결제 처리 중 오류가 발생했습니다.\n다시 시도해주세요.';

        throw PaymentException(
          code: 'PAYMENT_FAILED',
          message: errorMessage,
          status: 500,
        );
      }
    } catch (e) {
      _logger.severe('❌ 결제 실패: $e');
      rethrow;
    }
  }

  Future<void> chargePoint(int amount) async {
    try {
      await _apiClient.post(
        ApiEndpoints.chargePoint,
        {'amount': amount},
        (json) => json,
      );
    } catch (e) {
      _logger.severe('포인트 충전 실패: $e');
      throw PaymentException(
        code: 'CHARGE_FAILED',
        message: '충전 중 오류가 발생했습니다.',
        status: 500,
      );
    }
  }
}
