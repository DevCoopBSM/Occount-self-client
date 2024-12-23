import 'package:logging/logging.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/item_response.dart';
import '../models/payment_response.dart';
import '../exception/payment_exception.dart';
import '../models/payment_request.dart';
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
  }) async {
    try {
      // 충전 아이템과 일반 상품 분리
      final chargeItem = items.firstWhere(
        (item) => item.itemCategory == 'CHARGE',
        orElse: () => CartItem(
          itemId: 0,
          itemName: '',
          itemPrice: 0,
          quantity: 0,
          itemCategory: 'NONE',
          itemCode: '',
        ),
      );

      final productItems =
          items.where((item) => item.itemCategory != 'CHARGE').toList();

      // 요청 타입 결정
      PaymentType requestType;
      if (chargeItem.itemCategory == 'CHARGE' && productItems.isEmpty) {
        requestType = PaymentType.CHARGE;
      } else if (chargeItem.itemCategory == 'CHARGE' &&
          productItems.isNotEmpty) {
        requestType = PaymentType.MIXED;
      } else {
        requestType = PaymentType.PAYMENT;
      }

      _logger.info('💫 결제 요청 시작: $requestType');

      // 요청 객체 구성
      var request = PaymentRequest(
        type: requestType,
        userInfo: UserInfo(id: userCode),
      );

      // 충전 정보 추가
      if (chargeItem.itemCategory == 'CHARGE') {
        request = request.copyWith(
          charge: ChargeInfo(
            amount: chargeItem.itemPrice,
            method: 'CARD',
          ),
        );
        _logger.info('💳 충전 정보: ${chargeItem.itemPrice}원');
      }

      // 상품 결제 정보 추가
      if (productItems.isNotEmpty) {
        _logger.info('📦 상품 목록: ${productItems.length}개');
        final paymentItems =
            productItems.map((item) => PaymentItem.fromCartItem(item)).toList();

        final productTotalAmount = productItems.fold<int>(
            0, (sum, item) => sum + (item.itemPrice * item.quantity));

        request = request.copyWith(
          payment: PaymentInfo(
            items: paymentItems,
            totalAmount: productTotalAmount,
          ),
        );
        _logger.info('💰 상품 결제 정보: $productTotalAmount원');
      }

      _logger.info('📡 요청 데이터: ${jsonEncode(request.toJson())}');

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
        return response;
      } catch (e) {
        _logger.severe('❌ 결제 처리 중 오류: $e');
        if (e is PaymentException) {
          rethrow;
        }
        throw PaymentException(
          code: 'PAYMENT_FAILED',
          message: '결제 처리 중 오류가 발생했습니다.\n다시 시도해주세요.',
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
