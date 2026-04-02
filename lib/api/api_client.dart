import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'api_config.dart';
import '../exception/api_exception.dart';
import '../utils/api_key_generator.dart';

class ApiClient {
  final http.Client client;
  final ApiConfig apiConfig;
  final ApiKeyGenerator _keyGenerator;
  final Logger _logger = Logger('ApiClient');

  ApiClient({
    required this.client,
    required this.apiConfig,
  }) : _keyGenerator = ApiKeyGenerator(secretKey: apiConfig.API_KEY);

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final apiKey = _keyGenerator.generateApiKey();
    _logger.info('🔑 생성된 API 키: $apiKey');

    final headers = {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
    };

    if (requiresAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
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
  }) async {
    try {
      final uri = Uri.parse('${apiConfig.API_HOST}$endpoint')
          .replace(queryParameters: queryParams);
      _logger.info('🌐 GET 요청: $uri');

      final headers = await _getHeaders(requiresAuth: requiresAuth);
      _logger.fine('📤 Headers: $headers');

      final response = await client.get(
        uri,
        headers: headers,
      );

      _logger.info('📥 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        _logger.info('✅ GET 요청 성공');
        return fromJson(data);
      }

      _logger.warning('❌ GET 요청 실패: ${response.statusCode}');

      // 에러 응답 파싱 — 명세서 에러 형식: { "message": "ERROR_CODE" }
      final errorBody = utf8.decode(response.bodyBytes);
      final errorData = json.decode(errorBody);

      throw ApiException(
        // 명세서: 에러 코드가 json['message']에 담김 (구 API의 json['code']와 다름)
        code: _getErrorCodeFromStatus(response.statusCode, errorData['message']),
        message: errorData['message'] ?? '요청 실패: ${response.statusCode}',
        status: errorData['status'] ?? 'FAIL',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      _logger.severe('❌ GET 요청 에러: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  Future<T> post<T>(
    String endpoint,
    dynamic data,
    T Function(dynamic) parser, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${apiConfig.API_HOST}$endpoint');
      _logger.info('🌐 POST 요청: $uri');

      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      );

      _logger.info('📥 응답 상태 코드: ${response.statusCode}');
      _logger.fine('📥 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return parser(data);
      }

      // 에러 응답 처리 — 명세서 에러 형식: { "message": "ERROR_CODE" }
      String? errorCode;
      String? errorMessage;

      if (response.body.isNotEmpty) {
        try {
          final errorJson = jsonDecode(response.body);
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
      _logger.info('🌐 POST (header auth) 요청: $uri');

      // 로그인은 인증 불필요
      final headers = await _getHeaders(requiresAuth: false);
      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      );

      _logger.info('📥 응답 상태 코드: ${response.statusCode}');
      _logger.fine('📥 응답 헤더: ${response.headers}');

      if (response.statusCode == 201) {
        // 토큰은 Authorization 헤더에 "Bearer <token>" 형태로 담김
        final authHeader = response.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          _logger.severe('❌ Authorization 헤더 없음 또는 형식 오류');
          throw ApiException.fromErrorCode(ApiErrorCode.serverError);
        }
        final token = authHeader.substring('Bearer '.length);
        _logger.info('✅ 로그인 성공 — 토큰 추출 완료');
        return token;
      }

      // 에러 응답 처리 — 명세서 에러 형식: { "message": "ERROR_CODE" }
      String? errorCode;
      String? errorMessage;

      if (response.body.isNotEmpty) {
        try {
          final errorJson = jsonDecode(response.body);
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
      _logger.severe('❌ postForHeader 에러: $e');
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
      _logger.info('🌐 PUT 요청: $url');
      _logger.fine('📤 요청 바디: $body');

      final headers = await _getHeaders();
      _logger.fine('📤 Headers: $headers');

      final response = await client.put(
        url,
        headers: headers,
        body: json.encode(body),
      );

      _logger.info('📥 응답 상태 코드: ${response.statusCode}');
      _logger.fine('📥 응답 헤더: ${response.headers}');
      _logger.fine('📥 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        if (fromJson != null) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          _logger.info('✅ PUT 요청 성공');
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
        code: _getErrorCodeFromStatus(response.statusCode, errorData['message']),
        message: errorData['message'] ?? '요청 실패: ${response.statusCode}',
        status: errorData['status'] ?? 'FAIL',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      _logger.severe('❌ PUT 요청 에러: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  ApiErrorCode _getErrorCodeFromStatus(int statusCode, String? errorCode) {
    _logger.info('🔍 에러 매핑 시작');
    _logger.info('📥 서버 응답: statusCode=$statusCode, errorCode=$errorCode');

    // 명세서 에러 코드 직접 매핑 (json['message']로 받은 값)
    if (errorCode == 'DEFAULT_PIN_IN_USE') {
      _logger.info('✅ 초기 비밀번호 에러 감지');
      return ApiErrorCode.defaultPinInUse;
    }

    // 401 상태 코드에 대한 특별한 에러 코드 처리
    if (statusCode == 401) {
      if (errorCode == 'EXPIRED_TOKEN') {
        // 명세서: EXPIRED_TOKEN (구 API는 TOKEN_EXPIRED였음)
        _logger.info('✅ 토큰 만료 에러 감지');
        return ApiErrorCode.tokenExpired;
      } else if (errorCode == 'INVALID_TOKEN') {
        _logger.info('✅ 유효하지 않은 토큰 에러 감지');
        return ApiErrorCode.invalidToken;
      }
    }

    // 명세서 에러 코드로 ApiErrorCode 매핑
    if (errorCode != null) {
      _logger.info('📝 서버 에러 코드: "$errorCode"');
      for (var code in ApiErrorCode.values) {
        if (code.code == errorCode) {
          _logger.info('✅ 매칭된 에러 코드: ${code.code}');
          return code;
        }
      }
    }

    _logger.warning('⚠️ 기본 에러 매핑: statusCode=$statusCode');
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
        return ApiErrorCode.transactionInProgress;
      case 500:
        return ApiErrorCode.serverError;
      default:
        return ApiErrorCode.serverError;
    }
  }
}
