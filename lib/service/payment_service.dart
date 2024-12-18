import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../secure/db.dart';
import '../dto/item_response_dto.dart';
import '../models/user_info.dart';
import '../models/payment_response.dart';
import 'package:logging/logging.dart';

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
      if (chargeItem.type == 'CHARGE' && productItems.isNotEmpty) {
        requestType = "MIXED";
      } else if (chargeItem.type == 'CHARGE') {
        requestType = "CHARGE";
      }

      _logger.info('💫 결제 요청 시작: $requestType');
      if (productItems.isNotEmpty) {
        _logger.info('📦 상품 목록: ${productItems.length}개');
        for (var item in productItems) {
          _logger.info(
              '  - ID: ${item.itemId}, 이름: ${item.itemName}, 가격: ${item.itemPrice}원, 수량: ${item.quantity}');
        }
      }

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
        final paymentItems = productItems
            .map((item) => {
                  "itemId": item.itemId,
                  "itemName": item.itemName,
                  "itemPrice": item.itemPrice,
                  "quantity": item.quantity,
                  "totalPrice": item.itemPrice * item.quantity
                })
            .toList();

        final totalAmount = productItems.fold<int>(
            0, (sum, item) => sum + (item.itemPrice * item.quantity));

        requestBody["payment"] = {
          "items": paymentItems,
          "totalAmount": totalAmount
        };
        _logger.info('💰 상품 결제 정보: $totalAmount원');
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
    final response = await client.get(
      Uri.parse('${dbSecure.DB_HOST}/kiosk/item?itemCode=$itemCode'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('상품 정보를 가져오는데 실패했습니다');
    }

    final List<dynamic> itemJsonList =
        jsonDecode(utf8.decode(response.bodyBytes));
    if (itemJsonList.isEmpty) return null;

    final itemJson = itemJsonList.first;
    return ItemResponseDto(
      itemName: itemJson['itemName'],
      itemPrice: itemJson['itemPrice'],
      itemId: itemJson['itemId'],
      quantity: itemJson['quantity'] ?? 1,
      type: itemJson['eventStatus'] ?? 'NONE',
    );
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
}
