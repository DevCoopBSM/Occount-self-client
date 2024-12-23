# occount_self

셀프 카운터 애플리케이션을 위한 Flutter 프로젝트입니다.

## 개요

`occount_self`는 사용자가 셀프 서비스 방식으로 상품을 스캔하고 결제할 수 있도록 설계된 Flutter 애플리케이션입니다. 이 애플리케이션은 바코드 스캔, 상품 관리, 결제 처리, 사용자 인증 기능을 포함하고 있습니다.

## 주요 기능

- **바코드 스캔**: 사용자는 바코드를 스캔하여 장바구니에 상품을 추가할 수 있습니다.
- **상품 관리**: 사용자는 장바구니에 있는 상품을 관리하고, 바코드가 없는 상품도 추가할 수 있습니다.
- **결제 처리**: 카드 결제 및 포인트 차감을 지원하는 결제 처리 기능을 제공합니다.
- **사용자 인증**: 사용자별 데이터 및 거래를 관리하기 위한 안전한 사용자 인증을 제공합니다.

## 카드 결제 API

이 애플리케이션은 외부 카드 결제 API를 사용하여 결제를 처리합니다. 다음은 카드 결제 API 사용에 대한 간단한 안내입니다:

1. **API 설정**: `lib/services/payment_service.dart` 파일에서 API 엔드포인트와 인증 정보를 설정합니다.
2. **결제 요청**: `PaymentProvider` 클래스의 `processPayment` 메서드를 통해 결제 요청을 보냅니다.
3. **결제 결과 처리**: 결제 성공 또는 실패에 따라 UI에 결과를 표시합니다.

> **주의**: 실제 결제 API를 사용하기 전에 테스트 환경에서 충분히 검증하세요. API 키와 같은 민감한 정보는 안전하게 관리해야 합니다.

## 프로젝트 구조

- **lib/provider**: 상태 관리를 위한 provider 클래스들이 포함되어 있으며, `PaymentProvider`와 `AuthProvider`가 있습니다.
- **lib/services**: API 요청 및 비즈니스 로직을 처리하는 서비스 클래스들이 포함되어 있으며, `PaymentService`와 `ItemService`가 있습니다.
- **lib/ui**: 결제 처리에 대한 다이얼로그와 페이지를 포함한 UI 컴포넌트가 있습니다.
- **lib/models**: 애플리케이션 전반에서 사용되는 데이터 모델들이 정의되어 있습니다.

## 시작하기

이 프로젝트를 시작하려면, Flutter가 설치되어 있어야 합니다. 다음 명령어를 사용하여 저장소를 클론하고 애플리케이션을 실행할 수 있습니다:

```
bash
git clone <repository-url>
cd occount_self
flutter pub get
flutter run
```

## 리소스

Flutter 개발에 대한 추가 정보는 다음 리소스를 참고하세요:

- [Flutter 문서](https://docs.flutter.dev/)
- [Flutter Codelabs](https://docs.flutter.dev/get-started/codelab)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)

## 기여

이 프로젝트에 기여하고 싶다면, 저장소를 포크하고 변경 사항을 포함한 풀 리퀘스트를 제출해 주세요.

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.