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

  /// 명세서 로그인 흐름 (2단계):
  /// 1. POST /auth/kiosk/login → 201 응답 헤더에서 KIOSK_TOKEN 추출
  /// 2. GET /users/pre-order-info → 사용자 이름과 포인트 조회
  ///
  /// 요청 필드명 변경: userCode → userBarcode
  Future<AuthResponse> login(String userBarcode, String userPin) async {
    try {
      // Step 1: 로그인 — 토큰은 응답 body가 아닌 Authorization 헤더에 있음
      final token = await _apiClient.postForHeader(
        ApiEndpoints.login,
        {
          // 명세서 변경: 'userCode' → 'userBarcode'
          'userBarcode': userBarcode,
          'userPin': userPin,
        },
      );
      // Step 2를 위해 토큰을 미리 SharedPreferences에 저장
      // (인증이 필요한 /users/pre-order-info 호출을 위함)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', token);

      _logger.info('🔑 토큰 저장 완료, Step 2 시작');

      // Step 2: 사용자 이름과 포인트 조회 (단일 API로 통합됨)
      final userInfo = await _apiClient.get(
        ApiEndpoints.preOrderInfo,
        (json) => {
          'username': json['username'] as String,
          'point': json['point'] as int,
        },
        requiresAuth: true,
      );

      final username = userInfo['username'] as String;
      final point = userInfo['point'] as int;

      _logger.info('✅ Step 2 완료: $username, $point points');

      // 2단계 결과를 조합하여 AuthResponse 생성
      // userCode 자리에 userBarcode 사용 (사용자 식별자로 활용)
      // userNumber는 새 API에 없으므로 빈 문자열
      final response = AuthResponse(
        token: token,
        userInfo: UserInfo(
          userCode: userBarcode,
          userName: username,
          userNumber: '',
          userPoint: point,
        ),
      );

      _logger.info('✅ 로그인 전체 성공: ${response.userInfo.userName} (포인트: ${response.userInfo.userPoint})');
      return response;
    } catch (e) {
      _logger.severe('❌ 로그인 실패: $e');
      if (e is ApiException) rethrow;
      throw ApiException.fromErrorCode(ApiErrorCode.serverError);
    }
  }

  /// 현재 로그인된 사용자의 포인트 조회
  /// 명세서 변경: GET /users/pre-order-info에서 포인트도 함께 반환
  /// 별도의 /wallet/point API는 제거됨
  Future<int?> getPoint() async {
    try {
      _logger.info('💰 포인트 조회 시작');
      final userInfo = await _apiClient.get(
        ApiEndpoints.preOrderInfo,
        (json) => json['point'] as int,
        requiresAuth: true,
      );
      return userInfo;
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
