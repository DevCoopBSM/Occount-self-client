# PROJECT KNOWLEDGE BASE

**Generated:** 2026-04-27
**Commit:** f286133
**Branch:** develop

## OVERVIEW

Self-service kiosk Flutter app for barcode scanning, cart management, and point/card payments. Uses barcode+PIN auth → KIOSK_TOKEN. Provider + Service architecture.

## STRUCTURE

```
lib/
├── api/                 # ApiClient, ApiConfig, endpoints (3 files)
├── Dto/                 # DTOs (uppercase dir name - intentional)
├── exception/           # ApiException, PaymentException
├── models/              # Domain models with fromJson/toJson (13 files)
├── provider/            # ChangeNotifier state (8 files)
├── services/            # Business logic + API calls (8 files)
├── ui/
│   ├── _constant/       # Theme (colors, text styles), shared buttons
│   ├── components/      # Cross-cutting widgets (nav, dialogs)
│   ├── payments/widgets/# Payment UI widgets (18 files - largest dir)
│   └── ...              # Feature pages (login, home, pin, settings, etc.)
└── utils/               # Number formatting, sound utils
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add API endpoint | `lib/api/api_endpoints.dart` + matching service | ApiClient handles auth headers |
| Add new UI page | `lib/ui/<feature>/` | Follow Provider pattern for state |
| Fix payment flow | `lib/provider/payment_provider.dart` (824 lines) | Largest file, complex state |
| Auth/login issues | `lib/provider/auth_provider.dart` + `lib/services/auth_service.dart` | Token in SharedPreferences |
| Cart management | `lib/provider/auth_provider.dart` | Cart state lives in AuthProvider, shared with PaymentProvider |
| Category browsing | `lib/provider/category_provider.dart` + `lib/services/category_service.dart` | Lazy-loaded per category |
| Item lookup | `lib/services/item_service.dart` | Barcode + non-barcode item search with caching |
| Add data model | `lib/models/` | Must have fromJson/toJson |
| Add DTO | `lib/Dto/` | Uppercase dir — intentional, ask team before renaming |
| Error handling | `lib/exception/api_exception.dart` | Server returns `{ "message": "ERROR_CODE" }` |
| Kiosk configuration | `lib/services/kiosk_config_service.dart` + `lib/ui/setup/` | Setup checker for initial config |
| Theme/styling | `lib/ui/_constant/theme/` | GmarketSans fonts, DevCoop colors |
| SSE/streaming | `lib/services/event_service.dart` | Order status via SSE (placeholder — commented out) |
| CI/CD pipeline | `.gitlab-ci.yml` | GitLab CI, Windows runner, builds Windows + APK |

## CODE MAP

| Symbol | Type | Location | Role |
|--------|------|----------|------|
| `main()` | func | `lib/main.dart` | Bootstrap: DI, routing, providers |
| `AuthProvider` | provider | `lib/provider/auth_provider.dart` | Login state, user info, cart |
| `PaymentProvider` | provider | `lib/provider/payment_provider.dart` | Payment flow orchestration |
| `ItemProvider` | provider | `lib/provider/item_provider.dart` | Cart items, barcode lookup |
| `CategoryProvider` | provider | `lib/provider/category_provider.dart` | Category data, per-category items |
| `NavigationProvider` | provider | `lib/provider/navigation_provider.dart` | Navigation state |
| `BottomNavigationProvider` | provider | `lib/provider/bottom_navigation_provider.dart` | Bottom nav index state |
| `PinChangeProvider` | provider | `lib/provider/pin_change_provider.dart` | PIN change flow |
| `CountProvider` | provider | `lib/provider/count_provider.dart` | Simple counter state |
| `ApiClient` | class | `lib/api/api_client.dart` | HTTP client with auth interceptor |
| `ApiConfig` | class | `lib/api/api_config.dart` | Reads API_HOST from dart-define |
| `PaymentService` | service | `lib/services/payment_service.dart` | Order creation, payment execution |
| `PaymentCalculationService` | service | `lib/services/payment_calculation_service.dart` | PAYMENT vs MIXED determination |
| `KioskConfigService` | service | `lib/services/kiosk_config_service.dart` | Kiosk identity and config |
| `AuthService` | service | `lib/services/auth_service.dart` | Login, token management, user info |
| `ItemService` | service | `lib/services/item_service.dart` | Item lookup by barcode, caching |
| `CategoryService` | service | `lib/services/category_service.dart` | Category and per-category item fetch |
| `ChargeService` | service | `lib/services/charge_service.dart` | Charge item creation, local calculations |
| `EventService` | service | `lib/services/event_service.dart` | Placeholder (commented out) |
| `Home` | widget | `lib/ui/home/home.dart` | Main screen after auth |

## GIT CONVENTIONS

### 커밋 메시지
- **스타일**: Semantic (한국어) — `type: 설명`
- **타입**: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `style`, `perf`, `build`, `ci`
- **언어**: 한국어 (본문 포함)
- **예시**:
  - `feat: API 응답 시간 측정 로깅 추가`
  - `fix: 결제 취소 시 장바구니 복귀 및 주문 상태 폴링 주기 0.1초로 변경`
  - `chore: AGENTS.md 계층적 지식 베이스 추가`
- **규칙**: 타입은 영어, 설명은 한국어. 여러 파일 변경 시 모듈/관심사별로 분리 커밋.

### 브랜치 네이밍
- **기능**: `feature/설명` 또는 `scope/설명` (kebab-case)
- **예시**:
  - `feature/api-response-logging`
  - `order/status-checking-with-sse`
  - `improved-payment-apply`
- **기본 브랜치**: `develop` (PR 머지 대상)

### PR
- `develop` ← 브랜치 방향으로 PR 생성
- PR 제목도 한국어 + semantic 스타일 권장

## CONVENTIONS

- **State**: Provider + ChangeNotifier exclusively. No BLoC/Riverpod.
- **DI**: Two-layer in `main.dart` — `serviceProviders` (plain Provider) then `stateProviders` (ChangeNotifierProvider). Services injected into providers via `context.read<T>()`.
- **Models**: `fromJson`/`toJson` for serialization. No code generation (no freezed/json_serializable active despite being in pubspec).
- **Routing**: Named routes in `MaterialApp` (`/`, `/payment`, `/pin`, `/admin`). Root route dynamically shows Home or KioskSetupChecker based on AuthProvider state.
- **UI org**: Feature-based pages (`ui/login/`, `ui/payments/`) + shared components (`ui/components/`) + theme constants (`ui/_constant/`).
- **File naming**: `snake_case.dart` for files, `PascalCase` for classes.
- **Fonts**: GmarketSans family (B/L/M weights) + NotoSans via google_fonts.
- **Logging**: `logging` package with `debugPrintSynchronously` sink.

## ANTI-PATTERNS (THIS PROJECT)

- **NEVER hardcode API_HOST** — always inject via `--dart-define=API_HOST=...`
- **NEVER run `dart format .` or `flutter analyze` on entire project** — only changed files
- **NEVER suppress type errors** with `as any` equivalents or `// ignore:`
- **NEVER delete failing tests** to make CI pass
- **NEVER commit without explicit user request**
- `lib/Dto/` uses uppercase D — this is intentional, do not rename without team approval

## UNIQUE STYLES

- `Dto` directory is capitalized (non-standard for Dart)
- Payment type determined by comparing points balance to cart total: `points >= total` → PAYMENT, else MIXED
- Guest mode support: `X-Kiosk-Id` header instead of Bearer token
- Global navigator keys (`globalNavigatorKey`, `rootScaffoldMessengerKey`) for cross-widget navigation
- Immersive sticky UI mode (`SystemUiMode.immersiveSticky`) — kiosk-specific
- SSE streaming for order status watching via `event_service.dart`
- `get` package in dependencies but Provider used for state management (Get may be used only for navigation utilities)

## COMMANDS

```bash
# Run (API_HOST required)
flutter run --dart-define=API_HOST=http://YOUR_SERVER_IP/api/v3

# Web development
flutter run -d chrome --dart-define=API_HOST=https://YOUR_SERVER_IP:8443

# Build APK
flutter build apk --dart-define=API_HOST=http://YOUR_SERVER_IP/api/v3

# Release build
flutter build apk --release --dart-define=API_HOST=http://YOUR_SERVER_IP/api/v3

# Format changed files only
dart format lib/services/item_service.dart lib/provider/payment_provider.dart

# Analyze changed files only
flutter analyze lib/services/item_service.dart lib/provider/payment_provider.dart

# Tests
flutter test

# Install dependencies
flutter pub get
```

## NOTES

- `payment_provider.dart` (824 lines) is the largest and most complex file — payment flow has many edge cases
- `kiosk_config_page.dart` (493 lines) handles admin settings including WebSocket config
- No `freezed` or `json_serializable` code generation active despite being in pubspec.yaml (commented out)
- Test suite is minimal (3 test files) — covers payment service and two dialogs
- `charge_service.dart` has no API dependency — handles local charge calculations
- `count_provider.dart` exists but appears to be a simple counter state
- `event_service.dart` is a placeholder — all implementation commented out
- CI: GitLab CI (`.gitlab-ci.yml`) with Windows runner, builds Windows exe + APK using `--dart-define=DB_HOST`
- Android release builds use debug signing (no release keystore in repo)
- Cart state lives in `AuthProvider` — `PaymentProvider` reads cart via cross-provider access
- PaymentProvider cross-depends on AuthProvider at runtime (not via DI, via `Provider.of`)
- `PaymentCalculationService` determines payment type: `points >= total` → PAYMENT, else MIXED
- `PaymentService.watchOrderStatus` supports both SSE and polling (config via `KioskConfigService.isSseModeEnabled`)
- Flutter version in CI: 3.10.0; SDK constraint: `>=2.17.0 <4.0.0`
