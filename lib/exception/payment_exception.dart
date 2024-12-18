class PaymentException implements Exception {
  final String code;
  final String message;
  final int status;

  PaymentException({
    required this.code,
    required this.message,
    required this.status,
  });

  @override
  String toString() => message;
}
