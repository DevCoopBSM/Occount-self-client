import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:occount_self/api/api_client.dart';
import 'package:occount_self/api/api_config.dart';
import 'package:occount_self/exception/payment_exception.dart';
import 'package:occount_self/models/cart_item.dart';
import 'package:occount_self/models/order_status_response.dart';
import 'package:occount_self/services/kiosk_config_service.dart';
import 'package:occount_self/services/payment_service.dart';

class _TestApiConfig extends ApiConfig {
  @override
  // ignore: non_constant_identifier_names
  String get API_HOST => 'http://localhost';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaymentService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('createOrder sends spec-compliant body without auth for guest mode',
        () async {
      await _setPrefs(kioskId: 'KIOSK-001');

      late http.Request capturedRequest;
      final service = _buildService(
        MockClient((request) async {
          capturedRequest = request;

          expect(request.method, 'POST');
          expect(request.url.toString(), 'http://localhost/orders');
          expect(request.headers.containsKey('Authorization'), isFalse);
          expect(request.headers.containsKey('X-Kiosk-Id'), isFalse);

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['kioskId'], 'KIOSK-001');
          expect(body['totalAmount'], 9500);
          expect(body['orderInfos'], [
            {
              'itemId': 1,
              'itemName': '아메리카노',
              'itemPrice': 3000,
              'quantity': 2,
            },
            {
              'itemId': 2,
              'itemName': '카페라떼',
              'itemPrice': 3500,
              'quantity': 1,
            },
          ]);

          return http.Response(
            jsonEncode({
              'orderId': 'order-1',
              'status': 'PROCESSING',
            }),
            202,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final response = await service.createOrder(
        items: _sampleItems(),
        isGuestMode: true,
      );

      expect(
        capturedRequest.headers['Content-Type'],
        startsWith('application/json'),
      );
      expect(response.orderId, 'order-1');
      expect(response.status, OrderStatus.processing);
    });

    test('createOrder includes auth header for non-guest mode', () async {
      await _setPrefs(kioskId: 'KIOSK-001', accessToken: 'token-123');

      final service = _buildService(
        MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer token-123');

          return http.Response(
            jsonEncode({
              'orderId': 'order-2',
              'status': 'PROCESSING',
            }),
            202,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final response = await service.createOrder(items: _sampleItems());

      expect(response.orderId, 'order-2');
      expect(response.status, OrderStatus.processing);
    });

    test('createOrder fails locally when kioskId is missing', () async {
      final service = _buildService(
        MockClient((request) async {
          fail('HTTP should not be called when kioskId is missing');
        }),
      );

      await expectLater(
        service.createOrder(items: _sampleItems()),
        throwsA(
          isA<PaymentException>()
              .having((e) => e.code, 'code', 'KIOSK_ID_MISSING'),
        ),
      );
    });

    test('getOrderStatus polls public endpoint without auth header', () async {
      final service = _buildService(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.toString(), 'http://localhost/orders/order-3');
          expect(request.headers.containsKey('Authorization'), isFalse);

          return http.Response(
            jsonEncode({
              'orderId': 'order-3',
              'status': 'PROCESSING',
              'failureReason': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final response = await service.getOrderStatus('order-3');

      expect(response.orderId, 'order-3');
      expect(response.status, OrderStatus.processing);
      expect(response.failureReason, isNull);
    });

    test('pollOrderStatusUntilFinal keeps polling until terminal state',
        () async {
      var callCount = 0;
      final service = _buildService(
        MockClient((request) async {
          callCount += 1;

          late final String status;
          if (callCount == 1) {
            status = 'PENDING';
          } else if (callCount == 2) {
            status = 'PROCESSING';
          } else {
            status = 'COMPLETED';
          }

          return http.Response(
            jsonEncode({
              'orderId': 'order-4',
              'status': status,
              'failureReason': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final response = await service.pollOrderStatusUntilFinal(
        'order-4',
        interval: const Duration(milliseconds: 1),
        timeout: const Duration(milliseconds: 50),
      );

      expect(callCount, 3);
      expect(response.status, OrderStatus.completed);
    });

    test('pollOrderStatusUntilFinal returns TIMED_OUT on client-side timeout',
        () async {
      var callCount = 0;
      final service = _buildService(
        MockClient((request) async {
          callCount += 1;
          return http.Response(
            jsonEncode({
              'orderId': 'order-5',
              'status': 'PROCESSING',
              'failureReason': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final response = await service.pollOrderStatusUntilFinal(
        'order-5',
        interval: const Duration(milliseconds: 1),
        timeout: const Duration(milliseconds: 3),
      );

      expect(callCount, greaterThanOrEqualTo(1));
      expect(response.orderId, 'order-5');
      expect(response.status, OrderStatus.timedOut);
    });

    test('cancelOrder posts to cancel endpoint without auth for guest mode',
        () async {
      late http.Request capturedRequest;
      final service = _buildService(
        MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode({
              'orderId': 'order-6',
              'status': 'CANCEL_REQUESTED',
              'failureReason': '사용자에 의해 주문이 취소되었습니다',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final response = await service.cancelOrder(
        orderId: 'order-6',
        isGuestMode: true,
      );

      expect(capturedRequest.method, 'POST');
      expect(
        capturedRequest.url.toString(),
        'http://localhost/orders/order-6/cancel',
      );
      expect(capturedRequest.headers.containsKey('Authorization'), isFalse);
      expect(response.status, OrderStatus.cancelRequested);
      expect(response.failureReason, '사용자에 의해 주문이 취소되었습니다');
    });
  });
}

PaymentService _buildService(http.Client client) {
  final kioskConfigService = KioskConfigService();
  final apiClient = ApiClient(
    client: client,
    apiConfig: _TestApiConfig(),
    kioskConfigService: kioskConfigService,
  );

  return PaymentService(apiClient, kioskConfigService);
}

Future<void> _setPrefs({
  String? kioskId,
  String? accessToken,
}) async {
  SharedPreferences.setMockInitialValues({
    if (kioskId != null) 'kiosk_id': kioskId,
    if (accessToken != null) 'accessToken': accessToken,
  });
}

List<CartItem> _sampleItems() {
  return [
    CartItem(
      itemId: 1,
      itemCode: '880000000001',
      itemName: '아메리카노',
      itemPrice: 3000,
      itemCategory: 'BEVERAGE',
      quantity: 2,
    ),
    CartItem(
      itemId: 2,
      itemCode: '880000000002',
      itemName: '카페라떼',
      itemPrice: 3500,
      itemCategory: 'BEVERAGE',
      quantity: 1,
    ),
  ];
}
