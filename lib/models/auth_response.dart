import 'user_info.dart';

class AuthResponse {
  final String token;
  final UserInfo userInfo;
  final String? message;
  final String? redirectUrl;

  AuthResponse({
    required this.token,
    required this.userInfo,
    this.message,
    this.redirectUrl,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      userInfo: UserInfo(
        userCode: json['userCode'] as String,
        userName: json['userName'] as String,
        userNumber: json['userNumber'] as String,
        userPoint: json['userPoint'] as int,
      ),
      message: json['message'] as String?,
      redirectUrl: json['redirectUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userInfo': userInfo.toJson(),
      'message': message,
      'redirectUrl': redirectUrl,
    };
  }
}
