import 'user_info.dart';

// 명세서 변경: 로그인 응답이 단일 JSON body가 아님.
// token은 201 응답 헤더에서 받고, 사용자 정보는 /users/pre-order-info에서 조회한 뒤
// AuthResponse로 조합하여 생성한다.
// fromJson 제거 — AuthService.login()이 현재 2단계 흐름으로 직접 생성.
class AuthResponse {
  final String token;
  final UserInfo userInfo;

  AuthResponse({
    required this.token,
    required this.userInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userInfo': userInfo.toJson(),
    };
  }
}
