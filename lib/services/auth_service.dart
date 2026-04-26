import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../exception/api_exception.dart';
import '../models/auth_response.dart';
import '../models/user_info.dart';

class AuthService {
  final ApiClient _apiClient;
  final Logger _logger = Logger('AuthService');

  AuthService(this._apiClient);

  /// 명세서 로그인 흐름 (3단계):
  /// 1. POST /auth/kiosk/login → 201 응답 헤더에서 KIOSK_TOKEN 추출
  /// 2. GET /users/pre-order-info → 사용자 이름 조회
  /// 3. GET /wallet/point → 현재 포인트 조회
  ///
  /// 요청 필드명 변경: userCode → userBarcode

  Future<String> requestLoginToken(String userBarcode, String userPin) async {
    try {
      return await _apiClient.postForHeader(
        ApiEndpoints.login,
        {
          'userBarcode': userBarcode,
          'userPin': userPin,
        },
      );
    } catch (e) {
      _logger.severe('❌ 로그인 토큰 요청 실패 (타입: ${e.runtimeType}): $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  Future<void> persistAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
    _logger.info('🔑 토큰 저장 완료');
  }

  /// Step 1만 수행 — 토큰 획득 후 즉시 반환
  /// UI에서 빠른 화면 전환을 위해 사용자 정보 조회를 분리
  Future<String> loginForToken(String userBarcode, String userPin) async {
    try {
      final token = await requestLoginToken(userBarcode, userPin);
      await persistAccessToken(token);
      return token;
    } catch (e) {
      _logger.severe('❌ 로그인(토큰 획득) 실패 (타입: ${e.runtimeType}): $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  /// Step 2 & 3 — 토큰 획득 후 백그라운드에서 사용자 정보 조회
  Future<UserInfo> fetchUserInfo(String userBarcode) async {
    try {
      _logger.info('📋 사용자 정보 조회 시작');

      // Step 2: 사용자 이름 조회
      final username = await _apiClient.get(
        ApiEndpoints.preOrderInfo,
        (json) => json['username'] as String,
        requiresAuth: true,
      );

      // Step 3: 현재 포인트 조회
      final point = await _apiClient.get(
        ApiEndpoints.getPoint,
        (json) => json['point'] as int,
        requiresAuth: true,
      );

      _logger.info('✅ 사용자 정보 조회 완료: $username, $point points');

      return UserInfo(
        userCode: userBarcode,
        userName: username,
        userNumber: '',
        userPoint: point,
      );
    } catch (e) {
      _logger.severe('❌ 사용자 정보 조회 실패 (타입: ${e.runtimeType}): $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  /// 전체 로그인 (토큰 + 사용자 정보) — 하위 호환용
  Future<AuthResponse> login(String userBarcode, String userPin) async {
    final token = await loginForToken(userBarcode, userPin);
    final userInfo = await fetchUserInfo(userBarcode);

    final response = AuthResponse(
      token: token,
      userInfo: userInfo,
    );

    _logger.info(
        '✅ 로그인 전체 성공: ${response.userInfo.userName} (포인트: ${response.userInfo.userPoint})');
    return response;
  }

  /// 현재 로그인된 사용자의 포인트 조회
  /// GET /wallet/point (path param 없음, 토큰 기반)
  Future<int?> getPoint() async {
    try {
      _logger.info('💰 포인트 조회 시작');
      final point = await _apiClient.get(
        ApiEndpoints.getPoint,
        (json) => json['point'] as int,
        requiresAuth: true,
      );
      return point;
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
