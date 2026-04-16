class OrderStatus {
  static const String pending = 'PENDING';
  static const String processing = 'PROCESSING';
  static const String completed = 'COMPLETED';
  static const String failed = 'FAILED';
  static const String cancelRequested = 'CANCEL_REQUESTED';
  static const String compensating = 'COMPENSATING';
  static const String cancelled = 'CANCELLED';
  static const String compensationFailed = 'COMPENSATION_FAILED';
  static const String timedOut = 'TIMED_OUT';

  static const Set<String> terminalStatuses = {
    completed,
    failed,
    cancelled,
    compensationFailed,
    timedOut,
  };
}

class OrderStatusResponse {
  final String orderId;
  final String status;
  final String? failureReason;

  const OrderStatusResponse({
    required this.orderId,
    required this.status,
    this.failureReason,
  });

  bool get isTerminal => OrderStatus.terminalStatuses.contains(status);

  factory OrderStatusResponse.fromJson(Map<String, dynamic> json) {
    return OrderStatusResponse(
      orderId: json['orderId'] as String? ?? '',
      status: json['status'] as String? ?? OrderStatus.failed,
      failureReason: json['failureReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'status': status,
        'failureReason': failureReason,
      };
}
