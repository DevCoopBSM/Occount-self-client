class OrderStatus {
  static const String orderAccepted = 'ORDER_ACCEPTED';
  static const String paymentRequested = 'PAYMENT_REQUESTED';
  static const String processing = 'PROCESSING';
  static const String completed = 'COMPLETED';
  static const String failed = 'FAILED';
  static const String cancelRequested = 'CANCEL_REQUESTED';
  static const String cancelled = 'CANCELLED';
  static const String compensationFailed = 'COMPENSATION_FAILED';
  static const String timedOut = 'TIMED_OUT';

  static const Set<String> values = {
    orderAccepted,
    paymentRequested,
    processing,
    completed,
    failed,
    cancelRequested,
    cancelled,
    compensationFailed,
    timedOut,
  };

  static const Set<String> terminalStatuses = {
    completed,
    failed,
    cancelled,
    compensationFailed,
    timedOut,
  };

  /// SSE event type 문자열을 OrderStatus 상수로 변환한다.
  /// 명세서 SSE event types: order_accepted, payment_requested,
  /// completed, failed, cancel_requested, cancelled, timed_out
  static String fromSseEventType(String eventType) {
    switch (eventType) {
      case 'order_accepted':
        return orderAccepted;
      case 'payment_requested':
        return paymentRequested;
      case 'completed':
        return completed;
      case 'failed':
        return failed;
      case 'cancel_requested':
        return cancelRequested;
      case 'cancelled':
        return cancelled;
      case 'timed_out':
        return timedOut;
      default:
        return failed;
    }
  }
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
      orderId: (json['order_id'] ?? '').toString(),
      status: json['status'] as String? ?? OrderStatus.failed,
      failureReason: json['failure_reason'] as String?,
    );
  }

  /// SSE 이벤트에서 OrderStatusResponse를 생성한다.
  /// 명세서: event 필드가 상태를 결정하고, data는 {} 또는
  /// {"failure_reason": "..."} 형식이다.
  factory OrderStatusResponse.fromSseEvent({
    required String orderId,
    required String eventType,
    required Map<String, dynamic> data,
  }) {
    return OrderStatusResponse(
      orderId: orderId,
      status: OrderStatus.fromSseEventType(eventType),
      failureReason: data['failure_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'status': status,
        'failure_reason': failureReason,
      };
}
