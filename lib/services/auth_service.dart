import 'package:logging/logging.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../exception/api_exception.dart';
import '../models/auth_response.dart';

class AuthService {
  final ApiClient _apiClient;
  final Logger _logger = Logger('AuthService');

  AuthService(this._apiClient);

  Future<AuthResponse> login(String userCode, String userPin) async {
    try {
      _logger.info('🔐 로그인 시도');
      final response = await _apiClient.post(
        ApiEndpoints.login,
        {
          'userCode': userCode,
          'userPin': userPin,
        },
        (json) => AuthResponse.fromJson(json),
        requiresAuth: false,
      );
      _logger.info('✅ 로그인 성공');
      return response;
    } catch (e) {
      _logger.severe('❌ 로그인 실패: $e');
      if (e is ApiException) {
        rethrow; // ApiException을 그대로 전달
      }
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  Future<void> changePin(
      String codeNumber, String currentPin, String newPin) async {
    try {
      await _apiClient.put(
        ApiEndpoints.changePin,
        {
          'codeNumber': codeNumber,
          'pin': currentPin,
          'newPin': newPin,
        },
      );
    } catch (e) {
      _logger.severe('비밀번호 변경 실패: $e');
      throw ApiException.fromErrorCode(ApiErrorCode.changePinFailed);
    }
  }

  Future<void> validatePin(String userCode, String pin) async {
    try {
      _logger.info('🔐 PIN 번호 검증 시작');
      await _apiClient.post(
        ApiEndpoints.validatePin,
        {
          'userCode': userCode,
          'pin': pin,
        },
        (json) => json,
      );
      _logger.info('✅ PIN 번호 검증 성공');
    } catch (e) {
      _logger.severe('❌ PIN 번호 검증 실패: $e');
      throw ApiException(
        code: ApiErrorCode.invalidPin,
        message: 'PIN 번호가 일치하지 않습니다',
        status: '401',
      );
    }
  }

  Future<int?> getPoint(String userCode) async {
    try {
      _logger.info('💰 포인트 조회 시작');
      final response = await _apiClient.get(
        '${ApiEndpoints.getPoint}/$userCode',
        (json) => json['point'] as int,
      );
      _logger.info('✅ 포인트 조회 성공: $response');
      return response;
    } catch (e) {
      _logger.severe('❌ 포인트 조회 실패: $e');
      throw ApiException(
        code: ApiErrorCode.fetchPointFailed,
        message: '포인트 조회에 실패했습니다',
        status: '500',
      );
    }
  }
}
