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
          expect(request.headers['X-Kiosk-Id'], 'KIOSK-001');

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
          expect(request.headers['X-Kiosk-Id'], 'KIOSK-001');

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
      await _setPrefs(kioskId: 'KIOSK-001');

      final service = _buildService(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.toString(), 'http://localhost/orders/order-3');
          expect(request.headers.containsKey('Authorization'), isFalse);
          expect(request.headers['X-Kiosk-Id'], 'KIOSK-001');

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

    test('watchOrderStatus receives SSE updates and closes on terminal state',
        () async {
      await _setPrefs(kioskId: 'KIOSK-001');

      final service = _buildService(
        _StreamingTestClient((request) async {
          expect(request.method, 'GET');
          expect(
              request.url.toString(), 'http://localhost/orders/order-4/stream');
          expect(request.headers['Accept'], 'text/event-stream');
          expect(request.headers.containsKey('Authorization'), isFalse);
          expect(request.headers['X-Kiosk-Id'], 'KIOSK-001');

          return _streamResponse(
            [
              'data: {"orderId":"order-4","status":"PROCESSING","failureReason":null}\n\n',
              'data: {"orderId":"order-4","status":"COMPLETED","failureReason":null}\n\n',
            ],
          );
        }),
      );

      final events = await service.watchOrderStatus('order-4').toList();

      expect(events.map((event) => event.status), [
        OrderStatus.processing,
        OrderStatus.completed,
      ]);
    });

    test('watchOrderStatus falls back to single status fetch on SSE error',
        () async {
      await _setPrefs(kioskId: 'KIOSK-001');

      var streamRequestCount = 0;
      var fallbackRequestCount = 0;
      final service = _buildService(
        _StreamingTestClient((request) async {
          if (request.url.path == '/orders/order-5/stream') {
            streamRequestCount += 1;
            return _jsonStreamedResponse(
              500,
              {'message': 'SERVER_ERROR'},
            );
          }

          if (request.url.path == '/orders/order-5') {
            fallbackRequestCount += 1;
            return _jsonStreamedResponse(
              200,
              {
                'orderId': 'order-5',
                'status': 'COMPLETED',
                'failureReason': null,
              },
            );
          }

          fail('Unexpected request: ${request.method} ${request.url}');
        }),
      );

      final events = await service.watchOrderStatus('order-5').toList();

      expect(streamRequestCount, 1);
      expect(fallbackRequestCount, 1);
      expect(events, hasLength(1));
      expect(events.single.orderId, 'order-5');
      expect(events.single.status, OrderStatus.completed);
    });

    test('cancelOrder posts to cancel endpoint without auth for guest mode',
        () async {
      await _setPrefs(kioskId: 'KIOSK-001');

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
      expect(capturedRequest.headers['X-Kiosk-Id'], 'KIOSK-001');
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

class _StreamingTestClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request)
      _handler;

  _StreamingTestClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _handler(request);
  }
}

http.StreamedResponse _jsonStreamedResponse(
  int statusCode,
  Map<String, dynamic> body,
) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

http.StreamedResponse _streamResponse(List<String> chunks) {
  return http.StreamedResponse(
    Stream.fromIterable(chunks.map(utf8.encode)),
    200,
    headers: {'content-type': 'text/event-stream'},
  );
}
