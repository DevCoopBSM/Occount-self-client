class LoginResult {
  final bool success;
  final String? message;
  final String? redirectUrl;

  LoginResult({
    required this.success,
    this.message,
    this.redirectUrl,
  });
}
