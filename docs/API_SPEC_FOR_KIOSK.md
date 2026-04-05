# Occount — 키오스크 전용 API 명세서

> **Base URL:** `https://{host}/api/v3`
> **Content-Type:** `application/json`
> **대상:** 키오스크 클라이언트 전용 (터치 기반 무인 단말기)
> **전체 명세 참고:** [API_SPEC.md](./API_SPEC.md)

---

## 목차

- [키오스크 인증 방식](#키오스크-인증-방식)
- [API 목록 요약](#api-목록-요약)
- [인증 (Auth)](#인증-auth)
  - [POST /auth/kiosk/login](#post-authkiosklogin)
- [사용자 (Users)](#사용자-users)
  - [GET /users/pre-order-info](#get-userspre-order-info)
- [상품 (Items)](#상품-items)
  - [GET /items](#get-items)
  - [GET /items/categories](#get-itemscategories)
  - [GET /items/without-barcode](#get-itemswithout-barcode)
  - [GET /items/{barcode}](#get-itemsbarcode)
- [주문 (Orders)](#주문-orders)
  - [POST /orders](#post-orders)
- [결제 (Payments)](#결제-payments)
  - [POST /payments/execute](#post-paymentsexecute)
- [에러 응답](#에러-응답)
- [키오스크 사용 흐름](#키오스크-사용-흐름)

---

## 키오스크 인증 방식

키오스크는 이메일/비밀번호 방식이 아닌 **바코드 + PIN** 기반 인증을 사용합니다.

| 구분 | 설명 |
|------|------|
| **인증 헤더** | `Authorization: Bearer <KIOSK_TOKEN>` |
| **토큰 종류** | `KIOSK_TOKEN` — 키오스크 전용 JWT |
| **토큰 알고리즘** | HMAC-SHA (HS256) |
| **토큰 만료** | 서버 설정값 (`JWT_KIOSK_EXPIRATION_TIME`) |
| **토큰 획득** | `POST /auth/kiosk/login` 응답의 `Authorization` 헤더 |
| **게이트웨이 처리** | 토큰 검증 후 `X-Authenticated-User-Id` 헤더로 사용자 ID를 내부 서비스에 전달, 이후 `Authorization` 헤더는 제거됨 |

### 접근 권한 정책 (키오스크 관련)

| 접근 레벨 | 인증 필요 | 해당 API |
|-----------|-----------|----------|
| `PERMIT_ALL` | 불필요 | `POST /auth/kiosk/login`, `GET /items/**` |
| `AUTHENTICATED` | `KIOSK_TOKEN` 필요 | `GET /users/pre-order-info`, `POST /orders`, `POST /payments/execute` |

> **주의:** 키오스크 토큰(`KIOSK_TOKEN`)으로는 관리자 전용(`ADMIN_ONLY`) API에 접근할 수 없습니다.

---

## API 목록 요약

| # | Method | Endpoint | 인증 | 설명 |
|---|--------|----------|------|------|
| 1 | `POST` | `/auth/kiosk/login` | 불필요 | 바코드 + PIN으로 로그인 |
| 2 | `GET` | `/users/pre-order-info` | KIOSK_TOKEN | 주문 전 사용자 이름과 포인트 조회 |
| 3 | `GET` | `/items` | 불필요 | 전체 상품 목록 조회 |
| 4 | `GET` | `/items/categories` | 불필요 | 상품 카테고리 목록 조회 |
| 5 | `GET` | `/items/without-barcode` | 불필요 | 바코드 없는 상품 목록 조회 |
| 6 | `GET` | `/items/{barcode}` | 불필요 | 바코드로 상품 단건 조회 |
| 7 | `POST` | `/orders` | KIOSK_TOKEN | 주문 생성 |
| 8 | `POST` | `/payments/execute` | KIOSK_TOKEN | 결제 실행 |

---

## 인증 (Auth)

### POST /auth/kiosk/login

**설명:** 바코드와 PIN 번호로 키오스크 로그인을 수행합니다. 성공 시 `KIOSK_TOKEN`을 `Authorization` 응답 헤더로 반환합니다. 이후 인증이 필요한 모든 요청에 이 토큰을 사용합니다.

**인증:** 불필요

**비고:**
- PIN은 서버에 BCrypt로 암호화되어 저장되므로 평문으로 전송해도 안전합니다 (HTTPS 필수).
- 바코드는 사용자 카드 또는 앱에서 스캔하여 전달합니다.
- 기본 PIN은 서버 설정(`DEFAULT_PIN`)에 따라 초기화됩니다.

#### Request Body

| 필드 | 타입 | 필수 | 제약 조건 | 설명 |
|------|------|------|-----------|------|
| `userBarcode` | String | ✅ | Not Blank | 사용자 바코드 (카드 스캔 또는 앱 QR) |
| `userPin` | String | ✅ | Not Blank | PIN 번호 (숫자 4~6자리 권장) |

```json
// Request Body
{
  "userBarcode": "12345678",
  "userPin": "1234"
}
```

#### Response

| 상태 코드 | 설명 |
|-----------|------|
| `201 Created` | 로그인 성공 — `Authorization` 헤더에 `KIOSK_TOKEN` 반환 |
| `400 Bad Request` | PIN 번호 불일치 |
| `404 Not Found` | 바코드에 해당하는 사용자 없음 |

```
// 응답 헤더 (201 Created)
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI3IiwicGF5...
```

```json
// 400 Bad Request — PIN 불일치
{
  "message": "INVALID_PIN"
}

// 404 Not Found — 사용자 없음
{
  "message": "USER_NOT_FOUND"
}
```

---

## 사용자 (Users)

### GET /users/pre-order-info

**설명:** 로그인한 사용자의 이름과 포인트를 조회합니다. 키오스크 화면에서 "홍길동님, 안녕하세요" 와 같이 사용자를 맞이하고, 현재 포인트를 표시할 때 사용합니다.

**인증:** `AUTHENTICATED` — `Authorization: Bearer <KIOSK_TOKEN>` 헤더 필수

**비고:**
- 요청 파라미터 없이 JWT 내 사용자 ID를 기반으로 자동 조회됩니다.
- 로그인 직후 화면 초기화 시 호출을 권장합니다.
- 반환된 포인트 정보를 활용하여 결제 방식(포인트 단독 vs 혼합)을 미리 결정할 수 있습니다.

#### Request

```
GET /users/pre-order-info
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

#### Response

| 상태 코드 | 설명 |
|-----------|------|
| `200 OK` | 조회 성공 |
| `401 Unauthorized` | 토큰 없음, 유효하지 않음, 또는 만료됨 |
| `404 Not Found` | 사용자 없음 |

```json
// 200 OK
{
  "username": "구현우",
  "point": 0
}
```

```json
// 401 Unauthorized — 토큰 만료
{
  "message": "EXPIRED_TOKEN"
}

// 401 Unauthorized — 토큰 무효
{
  "message": "INVALID_TOKEN"
}
```

---

## 상품 (Items)

### GET /items

**설명:** 판매 중인 전체 상품 목록을 조회합니다. 키오스크 메인 화면의 상품 그리드를 구성할 때 사용합니다.

**인증:** 불필요

**비고:**
- `barcode`가 `null`인 상품은 바코드 스캔이 아닌 직접 선택 방식으로 주문합니다.
- `category` 필드를 기준으로 클라이언트에서 탭/필터를 구성할 수 있습니다.

#### Request

```
GET /items
```

#### Response

| 상태 코드 | 설명 |
|-----------|------|
| `200 OK` | 조회 성공 |

```json
// 200 OK
{
  "items": [
    {
      "itemId": 1,
      "name": "아메리카노",
      "category": "BEVERAGE",
      "price": 2000,
      "barcode": "8801234567890"
    },
    {
      "itemId": 2,
      "name": "샌드위치",
      "category": "FOOD",
      "price": 3500,
      "barcode": null
    }
  ]
}
```

#### Response Body 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `items` | Array | 상품 목록 |
| `items[].itemId` | Long | 상품 ID (주문/결제 요청 시 사용) |
| `items[].name` | String | 상품명 |
| `items[].category` | String | 카테고리 enum (예: `BEVERAGE`, `FOOD`, `SNACK`) |
| `items[].price` | Int | 판매 단가 (원) |
| `items[].barcode` | String \| null | 바코드 — `null`이면 직접 선택 상품 |

---

### GET /items/categories

**설명:** 상품 카테고리 목록을 조회합니다. 키오스크 상단의 카테고리 탭을 동적으로 렌더링할 때 사용합니다.

**인증:** 불필요

#### Request

```
GET /items/categories
```

#### Response

| 상태 코드 | 설명 |
|-----------|------|
| `200 OK` | 조회 성공 |

```json
// 200 OK
{
  "itemCategories": ["BEVERAGE", "FOOD", "SNACK"]
}
```

#### Response Body 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `itemCategories` | String[] | 카테고리 enum 값 목록 |

---

### GET /items/without-barcode

**설명:** 바코드가 없는 상품 목록만 조회합니다. 바코드 스캔으로 등록되지 않는 상품을 별도 패널로 표시할 때 사용합니다.

**인증:** 불필요

**비고:**
- `GET /items` 응답에서 `barcode == null`인 항목을 필터링한 것과 동일하나, 서버에서 직접 필터링된 결과를 반환합니다.
- `itemId`는 주문 요청(`POST /orders`) 시 사용합니다.

#### Request

```
GET /items/without-barcode
```

#### Response

| 상태 코드 | 설명 |
|-----------|------|
| `200 OK` | 조회 성공 |

```json
// 200 OK
{
  "items": [
    {
      "itemId": 2,
      "name": "샌드위치",
      "barcode": null,
      "price": 3500
    },
    {
      "itemId": 5,
      "name": "핫도그",
      "barcode": null,
      "price": 2500
    }
  ]
}
```

#### Response Body 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `items[].itemId` | Long | 상품 ID |
| `items[].name` | String | 상품명 |
| `items[].barcode` | null | 항상 `null` |
| `items[].price` | Int | 판매 단가 (원) |

---

### GET /items/{barcode}

**설명:** 바코드 스캔으로 특정 상품을 조회합니다. 스캐너로 바코드를 읽은 직후 상품 정보를 화면에 표시할 때 사용합니다.

**인증:** 불필요

**비고:**
- 스캔된 바코드가 DB에 없으면 `404`를 반환합니다. 이 경우 "등록되지 않은 상품입니다" 안내 메시지를 표시하세요.
- 반환된 `itemId`는 이후 주문(`POST /orders`) 및 결제(`POST /payments/execute`) 요청에 사용합니다.

#### Path Parameters

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `barcode` | String | ✅ | 스캐너로 읽은 상품 바코드 값 |

```
GET /items/8801234567890
```

#### Response

| 상태 코드 | 설명 |
|-----------|------|
| `200 OK` | 상품 조회 성공 |
| `404 Not Found` | 해당 바코드 상품 없음 |

```json
// 200 OK
{
  "itemId": 1,
  "name": "아메리카노",
  "barcode": "8801234567890",
  "price": 2000
}
```

```json
// 404 Not Found
{
  "message": "ITEM_NOT_FOUND"
}
```

#### Response Body 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `itemId` | Long | 상품 ID (주문/결제 요청 시 사용) |
| `name` | String | 상품명 |
| `barcode` | String | 조회한 바코드 값 |
| `price` | Int | 판매 단가 (원) |

---

## 주문 (Orders)

### POST /orders

**설명:** 사용자가 선택한 상품들로 주문을 생성합니다. 성공 시 내부적으로 Kafka `order.requested` 이벤트가 발행됩니다.

**인증:** `AUTHENTICATED` — `Authorization: Bearer <KIOSK_TOKEN>` 헤더 필수

**비고:**
- 주문 생성은 결제와 분리된 단계입니다. 주문 후 반드시 `POST /payments/execute`를 호출하여 결제를 완료해야 합니다.
- `itemId`는 `GET /items` 또는 `GET /items/{barcode}` 응답의 `itemId` 값을 사용합니다.
- `orderQuantity`는 1 이상의 정수여야 합니다.

#### Request Body

| 필드 | 타입 | 필수 | 제약 조건 | 설명 |
|------|------|------|-----------|------|
| `orderInfos` | Array | ✅ | 1개 이상 | 주문 상품 목록 |
| `orderInfos[].itemId` | Long | ✅ | 양수 | 상품 ID |
| `orderInfos[].orderQuantity` | Int | ✅ | 1 이상 | 주문 수량 |

```json
// Request Body
{
  "orderInfos": [
    {
      "itemId": 1,
      "orderQuantity": 2
    },
    {
      "itemId": 2,
      "orderQuantity": 1
    }
  ]
}
```

#### Response

| 상태 코드 | 설명 |
|-----------|------|
| `200 OK` | 주문 생성 성공 (응답 body 없음) |
| `400 Bad Request` | 잘못된 요청 (수량 오류 등) |
| `401 Unauthorized` | 토큰 없음, 유효하지 않음, 또는 만료됨 |

```json
// 401 Unauthorized
{
  "message": "EXPIRED_TOKEN"
}
```

---

## 결제 (Payments)

### POST /payments/execute

**설명:** 주문에 대한 결제를 실행합니다. 포인트 단독 결제(`PAYMENT`)와 포인트+카드 혼합 결제(`MIXED`) 두 가지 방식을 지원합니다.

**인증:** `AUTHENTICATED` — `Authorization: Bearer <KIOSK_TOKEN>` 헤더 필수

**비고:**
- 결제 전 `GET /users/pre-order-info`의 `point` 필드로 현재 포인트를 확인하여 결제 방식(포인트 단독 vs 혼합)을 결정하세요.
- `type: "PAYMENT"` — 포인트만으로 전액 결제. 잔액이 부족하면 `400` 반환.
- `type: "MIXED"` — 포인트를 먼저 사용하고 부족한 금액은 카드로 결제.
- `payment.items[].itemId`는 **String 타입**임에 유의하세요 (주문 요청의 `Long`과 다름).
- 결제 성공 후 반환된 `paymentLogId`를 영수증 출력 등 후처리에 활용할 수 있습니다.

#### Request Body

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `type` | String | ✅ | 결제 유형: `PAYMENT` (포인트 단독) / `MIXED` (포인트+카드 혼합) |
| `payment` | Object | ✅ | 결제 상세 정보 |
| `payment.items` | Array | ✅ | 결제 상품 목록 |
| `payment.items[].itemId` | **String** | ✅ | 상품 ID (문자열 타입) |
| `payment.items[].itemName` | String | ✅ | 상품명 |
| `payment.items[].itemPrice` | Int | ✅ | 상품 단가 (원) |
| `payment.items[].quantity` | Int | ✅ | 수량 |
| `payment.items[].totalPrice` | Int | ✅ | 해당 상품 합계 금액 (`itemPrice × quantity`) |
| `payment.totalAmount` | Int | ✅ | 전체 결제 총액 (원) |

```json
// 포인트 단독 결제 (PAYMENT)
{
  "type": "PAYMENT",
  "payment": {
    "items": [
      {
        "itemId": "1",
        "itemName": "아메리카노",
        "itemPrice": 2000,
        "quantity": 2,
        "totalPrice": 4000
      },
      {
        "itemId": "2",
        "itemName": "샌드위치",
        "itemPrice": 3500,
        "quantity": 1,
        "totalPrice": 3500
      }
    ],
    "totalAmount": 7500
  }
}
```

```json
// 포인트+카드 혼합 결제 (MIXED)
{
  "type": "MIXED",
  "payment": {
    "items": [
      {
        "itemId": "1",
        "itemName": "아메리카노",
        "itemPrice": 2000,
        "quantity": 1,
        "totalPrice": 2000
      }
    ],
    "totalAmount": 2000
  }
}
```

#### Response

| 상태 코드 | 설명 |
|-----------|------|
| `200 OK` | 결제 성공 |
| `400 Bad Request` | 포인트 잔액 부족 등 결제 실패 |
| `401 Unauthorized` | 토큰 없음, 유효하지 않음, 또는 만료됨 |
| `408 Request Timeout` | 결제 처리 타임아웃 |
| `409 Conflict` | 이미 진행 중인 결제 트랜잭션 존재 |

```json
// 200 OK — 포인트 단독 결제 성공
{
  "status": "SUCCESS",
  "type": "POINT",
  "totalAmount": 7500,
  "pointsUsed": 7500,
  "remainingPoints": 2500,
  "transactionId": "txn-uuid-1234",
  "paymentLogId": 42,
  "message": null,
  "chargedAmount": null,
  "paymentAmount": null,
  "cardAmount": null,
  "approvalNumber": null
}
```

```json
// 200 OK — 혼합 결제 성공
{
  "status": "SUCCESS",
  "type": "MIXED",
  "totalAmount": 10000,
  "pointsUsed": 6000,
  "cardAmount": 4000,
  "remainingPoints": 0,
  "approvalNumber": "APPR-9876",
  "transactionId": "txn-uuid-5678",
  "paymentLogId": 43,
  "message": null,
  "chargedAmount": null,
  "paymentAmount": null
}
```

```json
// 400 Bad Request — 포인트 부족
{
  "message": "INSUFFICIENT_POINTS"
}
```

#### Response Body 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `status` | String | 결제 결과: `SUCCESS` |
| `type` | String | 실제 결제 유형: `POINT` / `MIXED` |
| `totalAmount` | Int | 총 결제 금액 (원) |
| `pointsUsed` | Int \| null | 사용된 포인트 |
| `cardAmount` | Int \| null | 카드 결제 금액 (MIXED인 경우) |
| `remainingPoints` | Int \| null | 결제 후 남은 포인트 |
| `approvalNumber` | String \| null | 카드 승인 번호 (MIXED인 경우) |
| `transactionId` | String \| null | 트랜잭션 UUID |
| `paymentLogId` | Long \| null | 결제 로그 ID (영수증 등 후처리용) |
| `message` | String \| null | 부가 메시지 (오류 시 설명) |

---

## 에러 응답

모든 에러 응답은 아래 단일 형식을 따릅니다.

```json
{
  "message": "ERROR_CODE"
}
```

### 키오스크 관련 에러 코드

| HTTP 상태 | 에러 코드 | 발생 상황 | 키오스크 처리 권장 |
|-----------|-----------|-----------|-------------------|
| `400 Bad Request` | `INVALID_PIN` | PIN 번호 불일치 | "PIN 번호가 올바르지 않습니다" 안내 후 재입력 유도 |
| `401 Unauthorized` | `INVALID_TOKEN` | 유효하지 않은 JWT | 로그인 화면으로 이동 |
| `401 Unauthorized` | `EXPIRED_TOKEN` | JWT 만료 | "세션이 만료되었습니다" 안내 후 로그인 화면으로 이동 |
| `403 Forbidden` | `ACCESS_DENIED` | 권한 없음 (관리자 API 접근 시도 등) | 접근 불가 안내 |
| `404 Not Found` | `USER_NOT_FOUND` | 바코드에 해당하는 사용자 없음 | "등록되지 않은 사용자입니다" 안내 |
| `404 Not Found` | `ITEM_NOT_FOUND` | 바코드 스캔 시 상품 없음 | "등록되지 않은 상품입니다" 안내 |
| `400 Bad Request` | `INSUFFICIENT_POINTS` | 포인트 잔액 부족 | 포인트 충전 또는 혼합 결제 유도 |
| `408 Request Timeout` | — | 결제 타임아웃 | "결제 처리 중 시간이 초과되었습니다" 안내 후 재시도 |
| `409 Conflict` | — | 결제 트랜잭션 중복 | "이미 처리 중인 결제가 있습니다" 안내 후 대기 |
| `500 Internal Server Error` | — | 서버 내부 오류 | "서버 오류가 발생했습니다. 관리자에게 문의하세요" 안내 |

---

## 키오스크 사용 흐름

```
1. 카드/QR 스캔
       │
       ▼
2. POST /auth/kiosk/login
   → KIOSK_TOKEN 저장
       │
       ▼
3. GET /users/pre-order-info       ← 사용자 이름과 포인트 표시
   GET /items (또는 /items/categories)  ← 상품 목록 화면 구성
       │
       ├── 바코드 스캔 시 → GET /items/{barcode}
       └── 직접 선택 시  → GET /items/without-barcode
       │
       ▼
4. POST /orders                    ← 장바구니 확정 → 주문 생성
       │
       ▼
5. 보유 포인트 확인                 ← pre-order-info에서 가져온 포인트 사용
       │
       ├── 포인트 ≥ 총액  → type: "PAYMENT"
       └── 포인트 < 총액  → type: "MIXED"
       │
       ▼
6. POST /payments/execute          ← 결제 실행
       │
       ▼
7. 결제 완료 화면 (paymentLogId로 영수증 처리)
       │
       ▼
8. 세션 종료 (토큰 파기 권장)
```

> **세션 관리 권장사항:** 결제 완료 또는 일정 시간 비활성화 시 클라이언트 측에서 토큰을 파기하고 초기 화면으로 이동하세요. 키오스크 특성상 다음 사용자의 개인정보 노출을 방지하는 것이 중요합니다.
