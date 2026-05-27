import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'api_config.dart';
import '../exception/api_exception.dart';
import '../services/kiosk_config_service.dart';

class ApiClient {
  final http.Client client;
  final ApiConfig apiConfig;
  final KioskConfigService _kioskConfigService;
  final Logger _logger = Logger('ApiClient');

  static const Duration _requestTimeout = Duration(seconds: 5);

  ApiClient({
    required this.client,
    required this.apiConfig,
    required KioskConfigService kioskConfigService,
  }) : _kioskConfigService = kioskConfigService;

  Future<Map<String, String>> _getHeaders(
      {bool requiresAuth = true, bool includeKioskId = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    // 필요한 경우에만 명시적으로 키오스크 ID 헤더를 추가한다.
    if (includeKioskId) {
      final kioskId = await _kioskConfigService.getKioskId();
      if (kioskId != null && kioskId.isNotEmpty) {
        headers['X-Kiosk-Id'] = kioskId;
        _logger.info('🏪 X-Kiosk-Id 헤더 추가: $kioskId');
      } else {
        _logger.warning('⚠️ 키오스크 ID가 설정되지 않음 - X-Kiosk-Id 헤더 누락');
      }
    }

    return headers;
  }

  Future<T> get<T>(
    String endpoint,
    T Function(dynamic json) fromJson, {
    Map<String, dynamic>? queryParams,
    // 명세서상 /items/** 는 인증 불필요. 인증이 필요 없는 공개 API는 false 전달
    bool requiresAuth = true,
    bool includeKioskId = false,
  }) async {
    try {
      final uri = Uri.parse('${apiConfig.API_HOST}$endpoint')
          .replace(queryParameters: queryParams);
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        includeKioskId: includeKioskId,
      );

      final stopwatch = Stopwatch()..start();
      final response = await client.get(
        uri,
        headers: headers,
      ).timeout(_requestTimeout);
      stopwatch.stop();
      _logger.info(
        '⏱️ [GET] $endpoint - ${stopwatch.elapsedMilliseconds}ms '
        '(status: ${response.statusCode})',
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return fromJson(data);
      }

      _logger.warning('❌ GET 요청 실패: ${response.statusCode}');

      // 에러 응답 파싱 — 명세서 에러 형식: { "message": "ERROR_CODE" }
      final errorBody = utf8.decode(response.bodyBytes);
      final errorData = json.decode(errorBody);

      throw ApiException(
        // 명세서: 에러 코드가 json['message']에 담김 (구 API의 json['code']와 다름)
        code:
            _getErrorCodeFromStatus(response.statusCode, errorData['message']),
        message: errorData['message'] ?? '요청 실패: ${response.statusCode}',
        status: errorData['status'] ?? 'FAIL',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        _logger.severe('❌ GET 요청 타임아웃');
        throw ApiException.fromErrorCode(ApiErrorCode.connectionTimeout);
      }
      _logger.severe('❌ GET 요청 에러: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  Future<http.StreamedResponse> send(
    http.BaseRequest request, {
    bool requiresAuth = true,
    bool includeKioskId = false,
  }) async {
    try {
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        includeKioskId: includeKioskId,
      );
      request.headers.addAll(headers);

      final stopwatch = Stopwatch()..start();
      final response = await client.send(request).timeout(_requestTimeout);
      stopwatch.stop();
      _logger.info(
        '⏱️ [SEND] ${request.url} - ${stopwatch.elapsedMilliseconds}ms',
      );

      return response;
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        _logger.severe('❌ 요청 전송 타임아웃');
        throw ApiException.fromErrorCode(ApiErrorCode.connectionTimeout);
      }
      _logger.severe('❌ 요청 전송 에러: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  Future<T> post<T>(
    String endpoint,
    dynamic data,
    T Function(dynamic) parser, {
    bool requiresAuth = true,
    bool includeKioskId = false,
    List<int> successStatusCodes = const [200],
  }) async {
    try {
      final uri = Uri.parse('${apiConfig.API_HOST}$endpoint');

      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        includeKioskId: includeKioskId,
      );

      // 🔍 디버깅: 실제 HTTP 요청 로그
      _logger.info('🚀 [HTTP POST] URL: $uri');
      _logger.info('🚀 [HTTP POST] Headers: $headers');
      _logger.info('🚀 [HTTP POST] Body: ${jsonEncode(data)}');

      final stopwatch = Stopwatch()..start();
      final response = data == null
          ? await client.post(
              uri,
              headers: headers,
            ).timeout(_requestTimeout)
          : await client.post(
              uri,
              headers: headers,
              body: jsonEncode(data),
            ).timeout(_requestTimeout);
      stopwatch.stop();

      // 🔍 디버깅: 실제 HTTP 응답 로그
      _logger.info('📥 [HTTP RESPONSE] Status: ${response.statusCode}');
      _logger.info('📥 [HTTP RESPONSE] Headers: ${response.headers}');
      _logger.info('📥 [HTTP RESPONSE] Body: ${utf8.decode(response.bodyBytes)}');
      _logger.info(
        '⏱️ [POST] $endpoint - ${stopwatch.elapsedMilliseconds}ms '
        '(status: ${response.statusCode})',
      );

      if (successStatusCodes.contains(response.statusCode)) {
        // 빈 응답 처리
        if (response.body.isEmpty) {
          return parser(null);
        }
        final data = json.decode(utf8.decode(response.bodyBytes));
        return parser(data);
      }

      // 에러 응답 처리 — 명세서 에러 형식: { "message": "ERROR_CODE" }
      String? errorCode;
      String? errorMessage;

      if (response.body.isNotEmpty) {
        try {
          final errorJson = json.decode(utf8.decode(response.bodyBytes));
          // 명세서: 에러 코드가 json['message']에 담김 (구 API의 json['code']와 다름)
          errorCode = errorJson['message'];
          errorMessage = errorJson['message'];
        } catch (e) {
          _logger.severe('❌ 응답 파싱 에러: $e');
        }
      }

      final apiErrorCode =
          _getErrorCodeFromStatus(response.statusCode, errorCode);
      throw ApiException.fromErrorCode(apiErrorCode, errorMessage);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        _logger.severe('❌ POST 요청 타임아웃: $endpoint');
        throw ApiException.fromErrorCode(ApiErrorCode.connectionTimeout);
      }
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  /// 로그인 전용 — 201 응답의 Authorization 헤더에서 토큰 추출
  /// 명세서: POST /auth/kiosk/login 성공 시 201 Created,
  ///         응답 body 없음, 토큰은 Authorization 헤더에 담김
  Future<String> postForHeader(
    String endpoint,
    dynamic data,
  ) async {
    try {
      final uri = Uri.parse('${apiConfig.API_HOST}$endpoint');

      // 로그인은 인증 불필요
      final headers = await _getHeaders(requiresAuth: false);

      _logger.info('🚀 [LOGIN POST] URL: $uri');
      _logger.info('🚀 [LOGIN POST] Request Headers: $headers');
      _logger.info('🚀 [LOGIN POST] Request Body: ${jsonEncode(data)}');

      final stopwatch = Stopwatch()..start();
      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(_requestTimeout);
      stopwatch.stop();

      _logger.info('📥 [LOGIN RESPONSE] Status: ${response.statusCode}');
      _logger.info('📥 [LOGIN RESPONSE] Response Headers: ${response.headers}');
      _logger.info('📥 [LOGIN RESPONSE] Response Body: ${utf8.decode(response.bodyBytes)}');
      _logger.info(
        '⏱️ [LOGIN] $endpoint - ${stopwatch.elapsedMilliseconds}ms '
        '(status: ${response.statusCode})',
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // 토큰은 Authorization 헤더에 "Bearer <token>" 형태로 담김
        // HTTP 헤더는 case-insensitive이므로 소문자와 대문자 모두 확인
        final authHeader = response.headers['authorization'] ??
            response.headers['Authorization'];

        _logger.info('🔑 Authorization 헤더: $authHeader');

        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          _logger.severe('❌ Authorization 헤더 없음 또는 형식 오류');
          _logger.severe('❌ 사용 가능한 헤더들: ${response.headers.keys.toList()}');
          throw ApiException(
            code: ApiErrorCode.invalidToken,
            message: '잘못된 토큰 형식입니다',
            status: 'FAIL',
          );
        }
        final token = authHeader.substring('Bearer '.length);
        _logger.info('✅ 토큰 추출 성공');
        return token;
      }

      // 에러 응답 처리 — 명세서 에러 형식: { "message": "ERROR_CODE" }
      String? errorCode;
      String? errorMessage;

      if (response.body.isNotEmpty) {
        try {
          final errorJson = json.decode(utf8.decode(response.bodyBytes));
          errorCode = errorJson['message'];
          errorMessage = errorJson['message'];
        } catch (e) {
          _logger.severe('❌ 응답 바디 파싱 에러: $e / 원본 바디: ${utf8.decode(response.bodyBytes)}');
        }
      }

      final apiErrorCode =
          _getErrorCodeFromStatus(response.statusCode, errorCode);
      throw ApiException.fromErrorCode(apiErrorCode, errorMessage);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        _logger.severe('❌ 로그인 요청 타임아웃');
        throw ApiException.fromErrorCode(ApiErrorCode.connectionTimeout);
      }
      _logger.severe('❌ postForHeader 예외 (타입: ${e.runtimeType}): $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  Future<T> put<T>(
    String path,
    dynamic body, [
    T Function(Map<String, dynamic>)? fromJson,
  ]) async {
    try {
      final url = Uri.parse('${apiConfig.API_HOST}$path');

      // 주문 관련 엔드포인트인지 확인
      final isOrderEndpoint = path == '/orders' || path == '/payments/execute';
      final headers = await _getHeaders(includeKioskId: isOrderEndpoint);

      final stopwatch = Stopwatch()..start();
      final response = await client.put(
        url,
        headers: headers,
        body: json.encode(body),
      ).timeout(_requestTimeout);
      stopwatch.stop();
      _logger.info(
        '⏱️ [PUT] $path - ${stopwatch.elapsedMilliseconds}ms '
        '(status: ${response.statusCode})',
      );

      if (response.statusCode == 200) {
        if (fromJson != null) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          return fromJson(data);
        }
        return null as T;
      }

      _logger.warning('❌ PUT 요청 실패: ${response.statusCode}');

      // 에러 응답 파싱 — 명세서 에러 형식: { "message": "ERROR_CODE" }
      final errorBody = utf8.decode(response.bodyBytes);
      final errorData = json.decode(errorBody);

      throw ApiException(
        // 명세서: 에러 코드가 json['message']에 담김 (구 API의 json['code']와 다름)
        code:
            _getErrorCodeFromStatus(response.statusCode, errorData['message']),
        message: errorData['message'] ?? '요청 실패: ${response.statusCode}',
        status: errorData['status'] ?? 'FAIL',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        _logger.severe('❌ PUT 요청 타임아웃: $path');
        throw ApiException.fromErrorCode(ApiErrorCode.connectionTimeout);
      }
      _logger.severe('❌ PUT 요청 에러: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  ApiErrorCode _getErrorCodeFromStatus(int statusCode, String? errorCode) {
    // 명세서 에러 코드 직접 매핑 (json['message']로 받은 값)
    if (errorCode == 'DEFAULT_PIN_IN_USE') {
      return ApiErrorCode.defaultPinInUse;
    }

    // 401 상태 코드에 대한 특별한 에러 코드 처리
    if (statusCode == 401) {
      if (errorCode == 'EXPIRED_TOKEN') {
        // 명세서: EXPIRED_TOKEN (구 API는 TOKEN_EXPIRED였음)
        return ApiErrorCode.tokenExpired;
      } else if (errorCode == 'INVALID_TOKEN') {
        return ApiErrorCode.invalidToken;
      }
    }

    // 명세서 에러 코드로 ApiErrorCode 매핑
    if (errorCode != null) {
      for (var code in ApiErrorCode.values) {
        if (code.code == errorCode) {
          return code;
        }
      }
    }
    switch (statusCode) {
      case 400:
        return ApiErrorCode.paymentFailed;
      case 401:
        return ApiErrorCode.unauthorized;
      case 403:
        return ApiErrorCode.unauthorized;
      case 404:
        return ApiErrorCode.notFound;
      case 408:
        return ApiErrorCode.paymentTimeout;
      case 409:
        return ApiErrorCode.conflict;
      case 500:
        return ApiErrorCode.serverError;
      default:
        return ApiErrorCode.serverError;
    }
  }
}
