# Occount Self Client

셀프 카운터 애플리케이션을 위한 Flutter 프로젝트입니다.

## 개요

`occount_self`는 사용자가 셀프 서비스 방식으로 상품을 스캔하고 결제할 수 있도록 설계된 Flutter 애플리케이션입니다. 바코드 스캔, 상품 관리, 결제 처리, 사용자 인증 기능을 포함하고 있습니다.

## 주요 기능

- **바코드 스캔**: 바코드를 스캔하여 장바구니에 상품을 추가합니다.
- **상품 관리**: 장바구니 상품 관리, 바코드 없는 상품 직접 선택 지원.
- **결제 처리**: 포인트 단독(`PAYMENT`) 및 포인트+카드 혼합(`MIXED`) 결제 지원.
- **사용자 인증**: 바코드 + PIN 기반 KIOSK_TOKEN 인증.

## 시작하기

### 환경 변수 설정

API 서버 주소는 `--dart-define`으로 주입합니다. **하드코딩 금지.**

```bash
# 개발 실행
flutter run --dart-define=API_HOST=http://YOUR_SERVER_IP/api/v3

# 릴리즈 빌드
flutter build apk --dart-define=API_HOST=http://YOUR_SERVER_IP/api/v3
```

| 변수 | 설명 | 필수 |
|------|------|------|
| `API_HOST` | API 서버 Base URL (예: `http://192.168.1.100/api/v3`) | 

### 의존성 설치 및 실행

```bash
git clone <repository-url>
cd occount_self
flutter pub get
flutter run --dart-define=API_HOST=http://YOUR_SERVER_IP/api/v3
```

## API 연동

**Base URL**: `--dart-define=API_HOST` 로 주입
**인증 방식**: 로그인 시 발급된 `KIOSK_TOKEN` → `Authorization: Bearer <token>` 헤더

### 주요 흐름

```
1. POST /auth/kiosk/login         → 응답 헤더 Authorization에서 토큰 추출
2. GET  /users/pre-order-info     → 사용자 이름 조회
3. GET  /wallet/point             → 보유 포인트 조회
4. GET  /items/{barcode}          → 바코드 상품 조회 (path param)
5. POST /orders                   → 주문 생성 (결제 전 필수)
6. POST /payments/execute         → 결제 실행 (PAYMENT or MIXED)
```

### 결제 타입 결정

| 조건 | 타입 |
|------|------|
| 포인트 ≥ 총액 | `PAYMENT` (포인트 단독) |
| 포인트 < 총액 | `MIXED` (포인트 + 카드) |

## 프로젝트 구조

```
lib/
├── api/            # HTTP 클라이언트, 설정, 엔드포인트
├── Dto/            # Data Transfer Objects
├── exception/      # 커스텀 예외 클래스
├── models/         # 도메인 모델 (fromJson/toJson)
├── provider/       # 상태 관리 (Provider 패턴)
├── services/       # 비즈니스 로직 & API 호출
├── ui/             # UI 컴포넌트
└── utils/          # 유틸리티 (API 키 생성 등)
```
