// 명세서 변경: 응답 필드 전면 개편
// - success: 'success' → 'SUCCESS' (대문자)
// - pointsUsed: 신규 (사용한 포인트)
// - paymentLogId: 신규 (영수증 처리용)
// - cardAmount: 신규 (혼합결제 시 카드 결제 금액)
// - chargedAmount → cardAmount로 대응
// - balanceAfterCharge 제거
// - approvalNumber → transactionId로 대응 (카드 결제 시 사용)
class PaymentResponse {
  final bool success;
  final String message;
  final String type;
  final int chargedAmount;   // 내부 필드명 유지 (UI 레이어 호환), 실제로는 cardAmount
  final int balanceAfterCharge; // 제거됨, 0으로 고정
  final String approvalNumber;  // 내부 필드명 유지, 실제로는 transactionId
  final int remainingPoints;
  final int totalAmount;
  final int pointsUsed;
  final int? paymentLogId;

  PaymentResponse({
    required this.success,
    required this.message,
    this.type = '',
    this.chargedAmount = 0,
    this.balanceAfterCharge = 0,
    this.approvalNumber = '',
    required this.remainingPoints,
    this.totalAmount = 0,
    this.pointsUsed = 0,
    this.paymentLogId,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      // 명세서 변경: 'SUCCESS' (대문자) — 구 API는 'success' (소문자)
      success: json['status'] == 'SUCCESS',
      message: json['message'] ?? '',
      // 명세서: type은 'POINT' 또는 'MIXED'
      type: json['type'] ?? '',
      // 명세서 변경: 'chargedAmount' → 'cardAmount' (혼합결제 시 카드 결제 금액)
      chargedAmount: json['cardAmount'] ?? 0,
      // 명세서에서 balanceAfterCharge 제거됨
      balanceAfterCharge: 0,
      // 명세서 변경: 카드 승인번호는 approvalNumber (MIXED인 경우에만 존재)
      approvalNumber: json['approvalNumber'] ?? '',
      remainingPoints: json['remainingPoints'] ?? 0,
      totalAmount: json['totalAmount'] ?? 0,
      // 명세서 신규 필드: 사용한 포인트
      pointsUsed: json['pointsUsed'] ?? 0,
      // 명세서 신규 필드: 결제 로그 ID (영수증 출력 등 후처리용)
      paymentLogId: json['paymentLogId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': success ? 'SUCCESS' : 'FAIL',
      'message': message,
      'type': type,
      'cardAmount': chargedAmount,
      'approvalNumber': approvalNumber,
      'remainingPoints': remainingPoints,
      'totalAmount': totalAmount,
      'pointsUsed': pointsUsed,
      'paymentLogId': paymentLogId,
    };
  }
}
