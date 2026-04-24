# PROJECT KNOWLEDGE BASE

**Generated:** 2026-04-24
**Commit:** fae39d1
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
| Fix payment flow | `lib/provider/payment_provider.dart` (754 lines) | Largest file, complex state |
| Auth/login issues | `lib/provider/auth_provider.dart` + `lib/services/auth_service.dart` | Token in SharedPreferences |
| Add data model | `lib/models/` | Must have fromJson/toJson |
| Error handling | `lib/exception/api_exception.dart` | Server returns `{ "message": "ERROR_CODE" }` |
| Kiosk configuration | `lib/services/kiosk_config_service.dart` + `lib/ui/setup/` | Setup checker for initial config |
| Theme/styling | `lib/ui/_constant/theme/` | GmarketSans fonts, DevCoop colors |
| SSE/streaming | `lib/services/event_service.dart` | Order status via SSE |

## CODE MAP

| Symbol | Type | Location | Role |
|--------|------|----------|------|
| `main()` | func | `lib/main.dart` | Bootstrap: DI, routing, providers |
| `AuthProvider` | provider | `lib/provider/auth_provider.dart` | Login state, user info, cart |
| `PaymentProvider` | provider | `lib/provider/payment_provider.dart` | Payment flow orchestration |
| `ItemProvider` | provider | `lib/provider/item_provider.dart` | Cart items, barcode lookup |
| `ApiClient` | class | `lib/api/api_client.dart` | HTTP client with auth interceptor |
| `ApiConfig` | class | `lib/api/api_config.dart` | Reads API_HOST from dart-define |
| `PaymentService` | service | `lib/services/payment_service.dart` | Order creation, payment execution |
| `PaymentCalculationService` | service | `lib/services/payment_calculation_service.dart` | PAYMENT vs MIXED determination |
| `KioskConfigService` | service | `lib/services/kiosk_config_service.dart` | Kiosk identity and config |
| `Home` | widget | `lib/ui/home/home.dart` | Main screen after auth |

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

- `payment_provider.dart` (754 lines) is the largest and most complex file — payment flow has many edge cases
- `kiosk_config_page.dart` (493 lines) handles admin settings including WebSocket config
- No `freezed` or `json_serializable` code generation active despite being in pubspec.yaml (commented out)
- Test suite is minimal (3 test files) — covers payment service and two dialogs
- `charge_service.dart` has no API dependency — handles local charge calculations
- `count_provider.dart` exists but appears to be a simple counter state
