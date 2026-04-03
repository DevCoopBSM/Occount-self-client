# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Occount Self Client is a Flutter application for self-service kiosks. Users can scan barcodes, manage cart items, and process payments using points alone or mixed point+card payments. The app uses barcode+PIN authentication to generate KIOSK_TOKEN for API access.

## Development Commands

### Running the Application
```bash
# Development with API host (REQUIRED - no hardcoded URLs allowed)
flutter run --dart-define=API_HOST=http://YOUR_SERVER_IP/api/v3

# Web development
flutter run -d chrome --dart-define=API_HOST=https://YOUR_SERVER_IP:8443

# Install dependencies
flutter pub get
```

### Building
```bash
# Android APK
flutter build apk --dart-define=API_HOST=http://YOUR_SERVER_IP/api/v3

# Release build
flutter build apk --release --dart-define=API_HOST=http://YOUR_SERVER_IP/api/v3
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Check for lint issues
flutter analyze --fatal-infos --fatal-warnings
```

## Architecture Overview

### Core Pattern: Provider + Service Layer
- **Provider classes**: State management using `ChangeNotifier` pattern
- **Service classes**: Business logic and API communication
- **API Client**: Centralized HTTP client with authentication handling
- **Models**: Data classes with `fromJson`/`toJson` for API serialization

### Key Components

#### Authentication Flow
1. `BarcodeScanPage` → `PinPage` → API login
2. Token stored in SharedPreferences, added to API headers
3. `AuthProvider` manages login state and user info

#### Payment Flow
1. Items added to cart via barcode scan or manual selection
2. `PaymentProvider.processPayment()` determines payment type:
   - `PAYMENT`: Points ≥ total amount (points only)
   - `MIXED`: Points < total amount (points + card)
3. Order creation → Payment execution → Result dialog

#### API Configuration
- **Base URL**: Injected via `--dart-define=API_HOST` (never hardcoded)
- **Authentication**: Bearer token in Authorization header
- **Error handling**: Structured error codes in `ApiException`

### Directory Structure
```
lib/
├── api/                 # HTTP client, endpoints, configuration
├── Dto/                 # Data Transfer Objects
├── exception/           # Custom exception classes
├── models/              # Domain models with JSON serialization
├── provider/            # State management (ChangeNotifier)
├── services/            # Business logic & API calls
├── ui/                  # UI components and pages
│   ├── _constant/       # Shared UI constants, themes
│   ├── components/      # Reusable widgets
│   ├── login/           # Authentication pages
│   ├── payments/        # Payment flow UI
│   └── home/            # Main navigation
└── utils/               # Utility functions
```

### Key Services
- `AuthService`: Login, token management, user info
- `PaymentService`: Order creation, payment processing
- `ItemService`: Barcode scanning, product lookup
- `CategoryService`: Product categories for manual selection

### State Management Pattern
```dart
// Provider setup in main.dart
MultiProvider(
  providers: [
    // Service providers (no state)
    Provider<ApiClient>(create: (_) => apiClient),
    Provider<AuthService>(create: (_) => AuthService(apiClient)),

    // State providers (ChangeNotifier)
    ChangeNotifierProvider<AuthProvider>(
      create: (context) => AuthProvider(context.read<AuthService>()),
    ),
  ],
  child: App(),
)
```

### Critical Development Notes
- **API_HOST injection is mandatory**: Never hardcode server URLs
- **Token-based auth**: All authenticated endpoints require Bearer token
- **Error code mapping**: Server returns `{ "message": "ERROR_CODE" }` format
- **Payment type determination**: Based on user points vs total amount
- **Cart state**: Managed in `AuthProvider`, persists during session

### UI Navigation
- `/` (root): Auth check → `BarcodeScanPage` or `Home`
- `/payment`: Payment processing page
- `/pin`: PIN entry for authentication

### Testing & Debugging
- Use Flutter DevTools for state inspection
- Check logs with `Logger` output in debug console
- API requests/responses logged in `ApiClient`

### Common Development Tasks
- Adding new API endpoints: Update `api_endpoints.dart` and corresponding service
- New UI pages: Follow existing provider pattern for state management
- Error handling: Use `ApiException` with proper error codes
- Cart modifications: Always go through `AuthProvider` methods