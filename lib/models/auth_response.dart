import 'user_info.dart';

// 명세서 변경: 로그인 응답이 단일 JSON body가 아님.
// token은 201 응답 헤더에서, username은 /users/pre-order-info에서,
// point는 /wallet/point에서 각각 조회 후 조합하여 생성한다.
// fromJson 제거 — AuthService.login()이 현재 3단계 흐름으로 직접 생성한다.
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
