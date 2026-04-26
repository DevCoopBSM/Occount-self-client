class UserInfo {
  final String userCode;
  final String userName;
  final String userNumber;
  final int userPoint;

  UserInfo({
    required this.userCode,
    required this.userName,
    required this.userNumber,
    required this.userPoint,
  });

  factory UserInfo.empty() {
    return UserInfo(
      userCode: '',
      userName: '',
      userNumber: '',
      userPoint: 0,
    );
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userCode: json['user_code'] as String,
      userName: json['user_name'] as String,
      userNumber: json['user_number'] as String,
      userPoint: json['user_point'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_code': userCode,
      'user_name': userName,
      'user_number': userNumber,
      'user_point': userPoint,
    };
  }
}
