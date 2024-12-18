class UserInfo {
  int point;
  String name;
  String code;

  UserInfo({
    required this.point,
    required this.name,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'point': point,
      'name': name,
      'code': code,
    };
  }
}
