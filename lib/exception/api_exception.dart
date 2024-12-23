enum ApiErrorCode {
  unauthorized(401, 'UNAUTHORIZED'),
  notFound(404, 'NOT_FOUND'),
  serverError(500, 'SERVER_ERROR'),
  changePinFailed(400, 'CHANGE_PIN_FAILED'),
  paymentFailed(400, 'PAYMENT_FAILED'),
  itemNotFound(404, 'ITEM_NOT_FOUND'),
  invalidPin(401, 'INVALID_PIN'),
  fetchPointFailed(500, 'FETCH_POINT_FAILED');

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
      message: message ?? _getDefaultMessage(code),
      status: 'FAIL',
    );
  }

  static String _getDefaultMessage(ApiErrorCode code) {
    switch (code) {
      case ApiErrorCode.unauthorized:
        return '로그인에 실패했습니다.';
      case ApiErrorCode.notFound:
        return '요청한 리소스를 찾을 수 없습니다.';
      case ApiErrorCode.serverError:
        return '서버 오류가 발생했습니다.';
      case ApiErrorCode.changePinFailed:
        return '비밀번호 변경에 실패했습니다.';
      case ApiErrorCode.paymentFailed:
        return '결제에 실패했습니다.';
      case ApiErrorCode.itemNotFound:
        return '상품을 찾을 수 없습니다.';
      case ApiErrorCode.invalidPin:
        return '비밀번호가 올바르지 않습니다.';
      case ApiErrorCode.fetchPointFailed:
        return '포인트 조회에 실패했습니다.';
    }
  }

  @override
  String toString() => message;
}
