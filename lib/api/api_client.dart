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

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    _logger.fine('🔑 Using token: ${token?.substring(0, 10)}...');
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
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
      throw ApiException.fromErrorCode(
        _getErrorCodeFromStatus(response.statusCode),
        '요청 실패: ${response.statusCode}',
      );
    } catch (e) {
      _logger.severe('❌ GET 요청 에러: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  Future<T> post<T>(
    String path,
    dynamic body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final url = Uri.parse('${_apiConfig.API_HOST}$path');
      _logger.info('🌐 POST 요청: $url');
      _logger.fine('📤 요청 바디: $body');

      final headers = await _getHeaders();
      _logger.fine('📤 Headers: $headers');

      final response = await _client.post(
        url,
        headers: headers,
        body: json.encode(body),
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
      throw ApiException.fromErrorCode(
        _getErrorCodeFromStatus(response.statusCode),
        '요청 실패: ${response.statusCode}',
      );
    } catch (e) {
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
      throw ApiException.fromErrorCode(
        _getErrorCodeFromStatus(response.statusCode),
        '요청 실패: ${response.statusCode}',
      );
    } catch (e) {
      _logger.severe('❌ PUT 요청 에러: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  ApiErrorCode _getErrorCodeFromStatus(int statusCode) {
    _logger.fine('🔍 상태 코드 매핑: $statusCode');
    switch (statusCode) {
      case 401:
        return ApiErrorCode.unauthorized;
      case 404:
        return ApiErrorCode.notFound;
      case 500:
        return ApiErrorCode.serverError;
      default:
        return ApiErrorCode.serverError;
    }
  }
}
