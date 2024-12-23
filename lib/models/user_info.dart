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

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userCode: json['userCode'] as String,
      userName: json['userName'] as String,
      userNumber: json['userNumber'] as String,
      userPoint: json['userPoint'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCode': userCode,
      'userName': userName,
      'userNumber': userNumber,
      'userPoint': userPoint,
    };
  }
}
