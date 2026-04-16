```markdown
## 주문 (Orders)

### POST /orders

**설명:** 사용자가 선택한 상품들로 주문을 생성합니다. 성공 시 내부적으로 Kafka `order.requested` 이벤트가 발행됩니다.

**인증:** `AUTHENTICATED` — `Authorization: Bearer <KIOSK_TOKEN>` 헤더 필수

**비고:**
- 주문 생성은 비동기로 처리됩니다. 응답으로 받은 `orderId`로 `GET /orders/{orderId}`를 **폴링**하여 상태를 확인하세요.
- `itemId`는 `GET /items` 또는 `GET /items/{barcode}` 응답의 `itemId` 값을 사용합니다.
- `quantity`는 1 이상의 정수여야 합니다.
- `totalAmount`는 주문 상품 전체 합계 금액(원)을 전달합니다.
- `kioskId`는 현재 키오스크 식별자입니다 (취소 요청 시 검증에 사용됨).

#### Request Body

| 필드 | 타입 | 필수 | 제약 조건 | 설명 |
|------|------|------|-----------|------|
| `orderInfos` | Array | ✅ | 1개 이상 | 주문 상품 목록 (`items`로도 전송 가능) |
| `orderInfos[].itemId` | Long | ✅ | 양수 | 상품 ID |
| `orderInfos[].itemName` | String | ✅ | Not Blank | 상품명 |
| `orderInfos[].itemPrice` | Int | ✅ | 양수 | 상품 단가 (원) |
| `orderInfos[].quantity` | Int | ✅ | 1 이상 | 주문 수량 |
| `totalAmount` | Int | ✅ | 양수 | 주문 총 금액 (원) |
| `kioskId` | String | ✅ | Not Blank | 현재 키오스크 ID |

```json
// Request Body
{
  "orderInfos": [
    {
      "itemId": 1,
      "itemName": "아메리카노",
      "itemPrice": 3000,
      "quantity": 2
    },
    {
      "itemId": 2,
      "itemName": "카페라떼",
      "itemPrice": 3500,
      "quantity": 1
    }
  ],
  "totalAmount": 9500,
  "kioskId": "KIOSK-001"
}
```

#### Response

| 상태 코드 | 설명 |
|-----------|------|
| `202 Accepted` | 주문 생성 성공 — `orderId`를 사용해 폴링 시작 |
| `400 Bad Request` | 잘못된 요청 (수량 오류, 총액 불일치 등) |
| `401 Unauthorized` | 토큰 없음, 유효하지 않음, 또는 만료됨 |

```json
// 202 Accepted
{
  "orderId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "status": "PROCESSING"
}
```

```json
// 401 Unauthorized
{
  "message": "EXPIRED_TOKEN"
}
```

---

### GET /orders/{orderId} — 결제 상태 폴링

**설명:** 주문 생성(`POST /orders`) 이후, 비동기로 처리되는 재고 확보·결제 처리의 최종 상태를 확인하기 위해 주기적으로 호출하는 API입니다. 최종 상태(성공/실패/취소)가 될 때까지 **일정 간격으로 반복 호출(폴링)** 하세요.

**인증:** 불필요

**비고:**
- 주문은 생성 즉시 `PENDING` → `PROCESSING` 순으로 상태가 변경되며, 내부 이벤트 처리가 완료될 때까지 계속 변경됩니다.
- 서버 타임아웃은 **30초**입니다. 30초 내에 처리가 완료되지 않으면 상태가 `TIMED_OUT`으로 전환됩니다.
- 폴링은 **1~2초 간격**을 권장하며, 아래 **최종 상태** 중 하나가 반환되면 폴링을 중단하세요.

#### 주문 상태(`status`) 정의

| 상태 | 최종 여부 | 설명 | 키오스크 처리 |
|------|:---------:|------|--------------|
| `PENDING` | — | 주문 생성 직후, 아직 처리 시작 전 | 로딩 화면 유지, 계속 폴링 |
| `PROCESSING` | — | 재고 확보·결제 처리 진행 중 | 로딩 화면 유지, 계속 폴링 |
| `COMPLETED` | ✅ | 결제 완료 | 결제 완료 화면으로 이동 |
| `FAILED` | ✅ | 결제 또는 재고 처리 실패 | "결제에 실패했습니다" 안내 |
| `CANCEL_REQUESTED` | — | 취소 요청 접수, 보상 처리 대기 중 | 로딩 화면 유지, 계속 폴링 |
| `COMPENSATING` | — | 선 처리된 결제/재고를 원상 복구 중 | 로딩 화면 유지, 계속 폴링 |
| `CANCELLED` | ✅ | 주문이 정상적으로 취소됨 | "주문이 취소되었습니다" 안내 |
| `COMPENSATION_FAILED` | ✅ | 보상 처리 실패 — 운영자 개입 필요 | "오류가 발생했습니다. 관리자에게 문의하세요" 안내 |
| `TIMED_OUT` | ✅ | 30초 내 처리 미완료로 타임아웃 | "처리 시간이 초과되었습니다" 안내 |

> **최종 상태 판단:** `COMPLETED`, `FAILED`, `CANCELLED`, `COMPENSATION_FAILED`, `TIMED_OUT` 중 하나이면 폴링 종료.

#### Path Parameters

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `orderId` | String (UUID) | ✅ | `POST /orders` 응답의 `orderId` |

```
GET /orders/f47ac10b-58cc-4372-a567-0e02b2c3d479
```

#### Response

| 상태 코드 | 설명 |
|-----------|------|
| `200 OK` | 주문 조회 성공 |
| `404 Not Found` | 해당 `orderId` 주문 없음 |

#### Response Body 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `orderId` | String | 주문 ID (UUID) |
| `status` | String | 현재 주문 상태 (위 상태 정의 표 참고) |
| `failureReason` | String \| null | 실패 또는 취소 사유. 해당 없으면 `null` |

```json
// 200 OK — 처리 중 (폴링 계속)
{
  "orderId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "status": "PROCESSING",
  "failureReason": null
}
```

```json
// 200 OK — 결제 완료 (폴링 종료)
{
  "orderId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "status": "COMPLETED",
  "failureReason": null
}
```

```json
// 200 OK — 실패 (폴링 종료)
{
  "orderId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "status": "FAILED",
  "failureReason": "재고가 부족합니다."
}
```

```json
// 200 OK — 타임아웃 (폴링 종료)
{
  "orderId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "status": "TIMED_OUT",
  "failureReason": null
}
```

```json
// 404 Not Found
{
  "message": "주문 정보를 찾을 수 없습니다."
}
```

#### 폴링 구현 가이드

```
POST /orders  →  orderId 저장
      │
      ▼
┌─────────────────────────────┐
│  GET /orders/{orderId}      │  ← 1~2초 간격 반복
│                             │
│  status == 최종 상태?        │
│  (COMPLETED / FAILED /      │
│   CANCELLED / TIMED_OUT /   │
│   COMPENSATION_FAILED)      │
└────────┬────────────────────┘
         │ Yes
         ▼
    상태에 따라 화면 분기
```

> **타임아웃 처리:** 30초가 지나도 최종 상태가 되지 않으면 클라이언트 측에서도 폴링을 강제 종료하고 안내 메시지를 표시하세요.

---

### POST /orders/{orderId}/cancel — 주문 취소

**설명:** 진행 중인 주문에 취소를 요청합니다. 성공 시 주문 상태가 `CANCEL_REQUESTED`로 변경되고 내부적으로 보상 처리(결제·재고 원상복구)가 시작됩니다.

> **주의:** 이 API를 호출하면 즉시 취소가 완료되지 않습니다. 취소 처리도 비동기로 진행되므로, 이후 `GET /orders/{orderId}`를 폴링하여 `CANCELLED` 또는 `COMPENSATION_FAILED` 상태를 확인해야 합니다.

**인증:** `AUTHENTICATED` — `Authorization: Bearer <KIOSK_TOKEN>` 헤더 필수

**비고:**
- 취소 가능한 상태: `PENDING`, `PROCESSING`, `CANCEL_REQUESTED`, `COMPENSATING`
  - `COMPLETED`, `FAILED`, `CANCELLED`, `COMPENSATION_FAILED`, `TIMED_OUT` 상태에서는 취소 불가.
- `X-Kiosk-Id` 헤더는 게이트웨이에서 KIOSK_TOKEN을 파싱하여 자동으로 주입합니다. 클라이언트가 직접 설정할 필요 없습니다.
- 주문을 생성한 키오스크와 취소 요청 키오스크가 일치해야 합니다. 불일치 시 `403` 반환.

#### Path Parameters

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `orderId` | String (UUID) | ✅ | 취소할 주문의 ID |

```
POST /orders/f47ac10b-58cc-4372-a567-0e02b2c3d479/cancel
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

#### Request Body

없음 (Body 불필요)

#### Response

| 상태 코드 | 설명 |
|-----------|------|
| `200 OK` | 취소 요청 접수 성공 — 이후 폴링으로 최종 상태 확인 필요 |
| `403 Forbidden` | 다른 키오스크의 주문에 접근 시도 |
| `404 Not Found` | 해당 `orderId` 주문 없음 |
| `409 Conflict` | 취소 불가 상태 (`COMPLETED`, `FAILED`, `CANCELLED`, `COMPENSATION_FAILED`, `TIMED_OUT`) |

> `401 Unauthorized`는 게이트웨이 레벨에서 처리됩니다.

```json
// 200 OK — 취소 요청 접수
{
  "orderId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "status": "CANCEL_REQUESTED",
  "failureReason": "사용자에 의해 주문이 취소되었습니다"
}
```

```json
// 403 Forbidden — 다른 키오스크의 주문 취소 시도
{
  "message": "해당 주문에 접근할 수 없습니다."
}
```

```json
// 409 Conflict — 이미 완료된 주문 취소 시도
{
  "message": "현재 상태에서는 주문을 취소할 수 없습니다."
}
```

```json
// 404 Not Found
{
  "message": "주문 정보를 찾을 수 없습니다."
}
```

#### 취소 후 폴링 흐름

```
POST /orders/{orderId}/cancel
      │ 200 OK (status: CANCEL_REQUESTED)
      ▼
GET /orders/{orderId}  ← 1~2초 간격 반복
      │
      ├── CANCEL_REQUESTED / COMPENSATING  → 계속 폴링
      ├── CANCELLED                         → "주문이 취소되었습니다" 안내
      └── COMPENSATION_FAILED               → "오류가 발생했습니다. 관리자에게 문의하세요" 안내
```
```