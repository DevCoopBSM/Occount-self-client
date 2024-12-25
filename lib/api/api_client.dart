import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'api_config.dart';
import '../exception/api_exception.dart';

class ApiClient {
  final http.Client _client;
  final ApiConfig _apiConfig;
  final Logger _logger = Logger('ApiClient');

  ApiClient({
    required http.Client client,
    required ApiConfig apiConfig,
  })  : _client = client,
        _apiConfig = apiConfig;

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
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

    return headers;
  }

  Future<T> get<T>(
    String endpoint,
    T Function(dynamic json) fromJson, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('${_apiConfig.API_HOST}$endpoint')
          .replace(queryParameters: queryParams);
      _logger.info('🌐 GET 요청: $uri');

      final headers = await _getHeaders();
      _logger.fine('📤 Headers: $headers');

      final response = await _client.get(
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

      // 에러 응답 파싱 추가
      final errorBody = utf8.decode(response.bodyBytes);
      final errorData = json.decode(errorBody);

      throw ApiException(
        code: _getErrorCodeFromStatus(response.statusCode, errorData['code']),
        message: errorData['message'] ?? '요청 실패: ${response.statusCode}',
        status: errorData['status'] ?? 'FAIL',
      );
    } catch (e) {
      _logger.severe('❌ GET 요청 에러: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  Future<T> post<T>(
    String endpoint,
    dynamic body,
    T Function(dynamic json) fromJson, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${_apiConfig.API_HOST}$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      _logger.info('🌐 POST 요청: $uri');
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      _logger.info('📥 응답 상태 코드: ${response.statusCode}');
      _logger.fine('📥 응답 헤더: ${response.headers}');
      _logger.fine('📥 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        _logger.info('✅ POST 요청 성공');
        return fromJson(data);
      }

      _logger.warning('❌ POST 요청 실패: ${response.statusCode}');

      // 서버 에러 응답 파싱
      final errorBody = utf8.decode(response.bodyBytes);
      final errorData = json.decode(errorBody);

      final apiErrorCode =
          _getErrorCodeFromStatus(response.statusCode, errorData['code']);
      throw ApiException(
        code: apiErrorCode,
        message: errorData['message'] ?? '요청 실패: ${response.statusCode}',
        status: errorData['status'] ?? 'FAIL',
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      _logger.severe('❌ POST 요청 에러: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  Future<T> put<T>(
    String path,
    dynamic body, [
    T Function(Map<String, dynamic>)? fromJson,
  ]) async {
    try {
      final url = Uri.parse('${_apiConfig.API_HOST}$path');
      _logger.info('🌐 PUT 요청: $url');
      _logger.fine('📤 요청 바디: $body');

      final headers = await _getHeaders();
      _logger.fine('📤 Headers: $headers');

      final response = await _client.put(
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

      // 에러 응답 파싱 추가
      final errorBody = utf8.decode(response.bodyBytes);
      final errorData = json.decode(errorBody);

      throw ApiException(
        code: _getErrorCodeFromStatus(response.statusCode, errorData['code']),
        message: errorData['message'] ?? '요청 실패: ${response.statusCode}',
        status: errorData['status'] ?? 'FAIL',
      );
    } catch (e) {
      _logger.severe('❌ PUT 요청 에러: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  ApiErrorCode _getErrorCodeFromStatus(int statusCode, String? errorCode) {
    _logger.fine('🔍 상태 코드 매핑: $statusCode, 에러 코드: $errorCode');

    // 서버에서 보낸 에러 코드가 있으면 먼저 확인
    if (errorCode != null) {
      for (var code in ApiErrorCode.values) {
        if (code.code == errorCode) {
          return code;
        }
      }
    }

    // 기본 상태 코드 기반 매핑
    switch (statusCode) {
      case 401:
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
