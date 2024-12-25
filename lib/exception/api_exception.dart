enum ApiErrorCode {
  unauthorized(401, 'UNAUTHORIZED'),
  notFound(404, 'NOT_FOUND'),
  serverError(500, 'SERVER_ERROR'),
  changePinFailed(400, 'CHANGE_PIN_FAILED'),
  paymentFailed(400, 'PAYMENT_FAILED'),
  itemNotFound(404, 'ITEM_NOT_FOUND'),
  invalidPin(401, 'INVALID_PIN'),
  fetchPointFailed(500, 'FETCH_POINT_FAILED'),
  tokenExpired(401, 'TOKEN_EXPIRED'),
  paymentTimeout(408, 'PAYMENT_TIMEOUT'),
  paymentCancelled(400, 'PAYMENT_CANCELLED'),
  conflict(409, 'CONFLICT'),
  transactionInProgress(409, 'TRANSACTION_IN_PROGRESS');

  final int statusCode;
  final String code;

  const ApiErrorCode(this.statusCode, this.code);
}

class ApiException implements Exception {
  final ApiErrorCode code;
  final String message;
  final String status;

  ApiException({
    required this.code,
    required this.message,
    required this.status,
  });

  factory ApiException.fromErrorCode(ApiErrorCode code, [String? message]) {
    return ApiException(
      code: code,
      message: message ?? _getDefaultMessage(code.code),
      status: 'FAIL',
    );
  }

  static String _getDefaultMessage(String code) {
    switch (code) {
      case 'USER_NOT_FOUND':
        return '사용자를 찾을 수 없습니다';
      case 'INVALID_BARCODE':
        return '잘못된 바코드입니다';
      case 'ITEM_NOT_FOUND':
        return '상품을 찾을 수 없습니다';
      case 'FETCH_POINT_FAILED':
        return '포인트 조회에 실패했습니다';
      case 'PAYMENT_FAILED':
        return '결제 처리에 실패했습니다';
      case 'NETWORK_ERROR':
        return '네트워크 연결을 확인해주세요';
      case 'SERVER_ERROR':
        return '서버 오류가 발생했습니다';
      case 'UNKNOWN':
        return '알 수 없는 오류가 발생했습니다';
      case 'TRANSACTION_IN_PROGRESS':
        return '이미 진행 중인 거래가 있습니다';
      default:
        return '오류가 발생했습니다';
    }
  }

  @override
  String toString() => message;
}
