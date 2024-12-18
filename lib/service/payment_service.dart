import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../secure/db.dart';
import '../dto/item_response_dto.dart';
import '../models/user_info.dart';
import '../models/payment_response.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import '../ui/_constant/util/number_format_util.dart';

class PaymentService {
  final DbSecure dbSecure;
  final http.Client client;
  final _logger = Logger('PaymentService');

  PaymentService({
    required this.dbSecure,
    required this.client,
  });

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<PaymentResponse> executePayment({
    required List<ItemResponseDto> items,
    required UserInfo userInfo,
    required int totalAmount,
  }) async {
    try {
      final chargeItem = items.firstWhere(
        (item) => item.type == 'CHARGE',
        orElse: () => ItemResponseDto(
          itemId: '',
          itemName: '',
          itemPrice: 0,
          quantity: 0,
          type: 'NONE',
        ),
      );

      final productItems =
          items.where((item) => item.type != 'CHARGE').toList();

      String requestType = "PAYMENT";
      if (chargeItem.type == 'CHARGE' && productItems.isEmpty) {
        requestType = "CHARGE";
      } else if (chargeItem.type == 'CHARGE' && productItems.isNotEmpty) {
        requestType = "MIXED";
      }

      _logger.info('💫 결제 요청 시작: $requestType');

      final Map<String, dynamic> requestBody = {
        "type": requestType,
        "userInfo": {"id": userInfo.code}
      };

      if (chargeItem.type == 'CHARGE') {
        requestBody["charge"] = {
          "amount": chargeItem.itemPrice,
          "method": "CARD"
        };
        _logger.info('💳 충전 정보: ${chargeItem.itemPrice}원');
      }

      if (productItems.isNotEmpty) {
        _logger.info('📦 상품 목록: ${productItems.length}개');
        final paymentItems = productItems
            .map((item) => {
                  "itemId": item.itemId,
                  "itemName": item.itemName,
                  "itemPrice": item.itemPrice,
                  "quantity": item.quantity,
                  "totalPrice": item.itemPrice * item.quantity
                })
            .toList();

        final productTotalAmount = productItems.fold<int>(
            0, (sum, item) => sum + (item.itemPrice * item.quantity));

        requestBody["payment"] = {
          "items": paymentItems,
          "totalAmount": productTotalAmount
        };
        _logger.info('💰 상품 결제 정보: $productTotalAmount원');
      }

      final encodedBody = json.encode(requestBody);
      _logger.info('📡 서버 요청 데이터: $encodedBody');

      final response = await client.post(
        Uri.parse('${dbSecure.DB_HOST}/kiosk/executePayments'),
        headers: await _getHeaders(),
        body: encodedBody,
      );

      final responseData = json.decode(utf8.decode(response.bodyBytes));
      _logger.info('✅ 서버 응답: $responseData');

      return PaymentResponse.fromJson(responseData);
    } catch (e) {
      _logger.severe('❌ 결제 요청 에러: $e');
      return PaymentResponse(
          success: false,
          message: e.toString(),
          type: 'ERROR',
          remainingPoints: userInfo.point);
    }
  }

  Future<UserInfo> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final response = await client.get(
      Uri.parse('${dbSecure.DB_HOST}/kiosk/user/user-info'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('사용자 정보를 가져오는데 실패했습니다');
    }

    final data = json.decode(utf8.decode(response.bodyBytes));
    return UserInfo(
      point: data['userPoint'] ?? 0,
      name: data['userName'] ?? '',
      code: prefs.getString('userCode') ?? '',
    );
  }

  Future<ItemResponseDto?> getItemByBarcode(String itemCode) async {
    try {
      _logger.info('📡 바코드 상품 조회 요청: $itemCode');

      final uri =
          Uri.parse('${dbSecure.DB_HOST}/kiosk/item?itemCode=$itemCode');
      _logger.info('📡 요청 URL: $uri');

      final headers = await _getHeaders();
      _logger.info('📡 요청 헤더: $headers');

      final response = await client.get(uri, headers: headers);

      _logger.info('📡 서버 응답 상태코드: ${response.statusCode}');
      _logger.info('📡 서버 응답 바디: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode != 200) {
        throw Exception(
            '상품 정보를 가져오는데 실패했습니다. 상태코드: ${response.statusCode}, 응답: ${utf8.decode(response.bodyBytes)}');
      }

      final List<dynamic> itemJsonList =
          jsonDecode(utf8.decode(response.bodyBytes));
      if (itemJsonList.isEmpty) {
        _logger.info('❌ 바코드에 해당하는 상품이 없습니다: $itemCode');
        return null;
      }

      final itemJson = itemJsonList.first;
      _logger.info('✅ 상품 조회 성공: $itemJson');

      return ItemResponseDto(
        itemName: itemJson['itemName'],
        itemPrice: itemJson['itemPrice'],
        itemId: itemJson['itemId'].toString(),
        quantity: itemJson['quantity'] ?? 1,
        type: itemJson['eventStatus'] ?? 'NONE',
      );
    } catch (e, stackTrace) {
      _logger.severe('❌ 상품 조회 중 에러 발생', e, stackTrace);
      throw Exception('상품 정보를 가져오는데 실패했습니다: $e');
    }
  }

  Future<List<ItemResponseDto>> getNonBarcodeItems() async {
    final response = await client.get(
      Uri.parse('${dbSecure.DB_HOST}/kiosk/items/no-barcode'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('바코드 없는 상품 목록을 가져오는데 실패했습니다');
    }

    final List<dynamic> itemsJson = jsonDecode(utf8.decode(response.bodyBytes));
    return itemsJson
        .map((json) => ItemResponseDto(
              itemName: json['itemName'] ?? '',
              itemPrice: json['itemPrice'] ?? 0,
              itemId: json['itemId'].toString(),
              quantity: json['quantity'] ?? 1,
              type: json['eventStatus'] ?? 'NONE',
            ))
        .toList();
  }

  Future<void> processPayment({
    required List<ItemResponseDto> items,
    required UserInfo userInfo,
    required int totalAmount,
    required Function(PaymentResponse) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      _logger.log(Level.INFO, '💳 결제 프로세스 시작');
      final response = await executePayment(
        items: items,
        userInfo: userInfo,
        totalAmount: totalAmount,
      ).timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          _logger.severe('❌ 결제 타임아웃 발생 (35초 초과)');
          throw TimeoutException('결제 처리 시간이 초과되었습니다');
        },
      );

      if (response.success) {
        _logger.log(Level.INFO, '✅ 결제 성공');
        onSuccess(response);
      } else {
        _logger.severe('❌ 결제 실패: ${response.message}');
        onError(response.message);
      }
    } catch (e) {
      _logger.severe('❌ 결제 처리 중 예외 발생', e);
      onError("결제 처리 중 오류가 발생했습니다.\n다시 시도해 주세요.");
    } finally {
      _logger.log(Level.INFO, '🔄 결제 프로세스 종료');
    }
  }

  int calculateCardAmount({
    required List<ItemResponseDto> items,
    required int totalPrice,
    required int currentPoints,
    required bool isChargeOnly,
  }) {
    if (isChargeOnly) {
      _logger.log(Level.INFO, '💰 순수 충전 금액 계산: $totalPrice원');
      return totalPrice;
    }

    final chargeAmount = items
        .where((item) => item.type == 'CHARGE')
        .fold<int>(0, (sum, item) => sum + (item.itemPrice * item.quantity));

    final paymentAmount = totalPrice - chargeAmount;
    final cardPaymentAmount =
        paymentAmount > currentPoints ? paymentAmount - currentPoints : 0;

    final totalCardAmount = chargeAmount + cardPaymentAmount;
    _logger.log(Level.INFO,
        '💰 카드 결제 금액 계산 - 충전: $chargeAmount원, 결제: $cardPaymentAmount원, 총: $totalCardAmount원');

    return totalCardAmount;
  }

  String buildResultMessage({
    required PaymentResponse response,
    required bool isChargeRequest,
    required int totalPrice,
    required int currentPoints,
  }) {
    if (isChargeRequest) {
      return "충전금액: ${NumberFormatUtil.convert1000Number(response.chargedAmount)}원\n"
          "잔여금액: ${NumberFormatUtil.convert1000Number(response.balanceAfterCharge)}원\n"
          "승인번호: ${response.approvalNumber}";
    }

    final cardAmount =
        totalPrice > currentPoints ? totalPrice - currentPoints : 0;

    return "결제금액: ${NumberFormatUtil.convert1000Number(response.totalAmount)}원\n"
        "${cardAmount > 0 ? "카드결제: ${NumberFormatUtil.convert1000Number(cardAmount)}원\n" : ""}"
        "잔여금액: ${NumberFormatUtil.convert1000Number(response.remainingPoints)}원\n"
        "${response.approvalNumber.isNotEmpty ? "승인번호: ${response.approvalNumber}" : ""}";
  }

  bool isChargeOnlyTransaction(List<ItemResponseDto> items) {
    return items.every((item) => item.type == 'CHARGE');
  }

  bool hasChargeItem(List<ItemResponseDto> items) {
    return items.any((item) => item.type == 'CHARGE');
  }
}
