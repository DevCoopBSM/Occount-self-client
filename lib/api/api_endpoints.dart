// 명세서 기준: Base URL = API_HOST (--dart-define으로 주입)
// 예: http://192.168.5.163/api/v3
class ApiEndpoints {
  // POST /auth/kiosk/login — 인증 불필요, 응답 헤더에서 KIOSK_TOKEN 추출
  static const String login = '/auth/kiosk/login';

  // GET /users/pre-order-info — KIOSK_TOKEN 필요, 사용자 이름 조회
  static const String preOrderInfo = '/users/pre-order-info';

  // GET /items — 인증 불필요, 전체 상품 목록 (category 포함)
  static const String getItems = '/items';

  // GET /items/categories — 인증 불필요, 카테고리 목록
  static const String getItemCategories = '/items/categories';

  // GET /items/without-barcode — 인증 불필요, 바코드 없는 상품 목록
  static const String getNonBarcodeItems = '/items/without-barcode';

  // GET /items/{barcode} — 인증 불필요, 바코드로 단건 조회 (path param)
  // 사용: '${ApiEndpoints.getItems}/$barcode'
  // (getItems 상수를 prefix로 사용)

  // POST /orders — KIOSK_TOKEN 필요, 주문 생성 (결제 전 필수)
  static const String createOrder = '/orders';

  // GET /orders/{orderId} — 주문 상태 조회
  static String getOrderStatus(String orderId) => '/orders/$orderId';

  // POST /orders/{orderId}/cancel — 주문 취소 요청
  static String cancelOrder(String orderId) => '/orders/$orderId/cancel';

  // POST /payments/execute — KIOSK_TOKEN 필요, 결제 실행
  static const String executePayment = '/payments/execute';

  // GET /wallet/point — KIOSK_TOKEN 필요, 현재 포인트 조회
  static const String getPoint = '/wallet/point';
}
