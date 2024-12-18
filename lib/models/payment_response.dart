class PaymentResponse {
  final bool success;
  final String message;
  final String type;
  final int chargedAmount;
  final int balanceAfterCharge;
  final String approvalNumber;
  final int remainingPoints;
  final int totalAmount;

  PaymentResponse({
    required this.success,
    required this.message,
    this.type = '',
    this.chargedAmount = 0,
    this.balanceAfterCharge = 0,
    this.approvalNumber = '',
    required this.remainingPoints,
    this.totalAmount = 0,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['status'] == 'success',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      chargedAmount: json['chargedAmount'] ?? 0,
      balanceAfterCharge: json['balanceAfterCharge'] ?? 0,
      approvalNumber: json['approvalNumber'] ?? '',
      remainingPoints: json['remainingPoints'] ?? 0,
      totalAmount: json['totalAmount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': success ? 'success' : 'error',
      'message': message,
      'type': type,
      'chargedAmount': chargedAmount,
      'balanceAfterCharge': balanceAfterCharge,
      'approvalNumber': approvalNumber,
      'remainingPoints': remainingPoints,
      'totalAmount': totalAmount,
    };
  }
}
