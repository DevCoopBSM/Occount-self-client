# 주문 상태 확인 SSE API 명세

기본 정보

인증: X

API 정보

Endpoint & Request

GET /api/v3/orders/{orderId}/stream

Response (SSE)

Response Headers

Content-Type: text/event-stream                                                                                                                                         
Cache-Control: no-cache
Connection: keep-alive

이벤트 프레임 포멧

각 이벤트는 다음 프레임으로 전송됩니다. JSON 페이로드는 UTF-8 그대로(ensure_ascii=false) 직렬화됩니다.

event: <event_type>
data: <json payload>

이벤트 타입

event_type

payload 필드

발생 시점 / 보장

order_accepted



주문 생성 직후 또는 PROCESSING 중

payment_requested



재고 확인 완료 후 결제 요청 시

completed



주문 완료

failed

failure_reason

재고 부족·결제 실패 등 

cancel_requested



취소 요청 접수

cancelled



취소 완료

timed_out

failure_reason

처리 시간 초과

이벤트 발생 순서 보장

order_accepted
  → payment_requested
  → completed | failed | timed_out

order_accepted
  → payment_requested
  → cancel_requested
  → cancelled | failed | timed_out

SSE 응답 예시 - 주문 완료

event: order_accepted
data: {}
event: payment_requested
data: {}
event: completed
data: {}

SSE 응답 예시 - 주문 실패

event: order_accepted
data: {}
event: failed
data: {"failure_reason": "재고 부족"}

SSE 응답 예시 - 주문 취소

event: order_accepted
data: {}
event: payment_requested
data: {}
event: cancel_requested
data: {}
event: cancelled
data: {}