import 'package:logging/logging.dart';

class ApiConfig {
  final String apiHost;
  final Logger _logger = Logger('ApiConfig');

  ApiConfig()
      // API_HOST는 --dart-define=API_HOST=http://... 로 주입해야 함
      // 예: flutter run --dart-define=API_HOST=http://192.168.5.163/api/v3
      : apiHost = const String.fromEnvironment('API_HOST', defaultValue: '') {
    if (apiHost.isEmpty) {
      // 하드코딩 금지 — 반드시 --dart-define=API_HOST=... 로 지정할 것
      Logger('ApiConfig').warning(
        '⚠️ API_HOST가 설정되지 않았습니다. '
        '--dart-define=API_HOST=http://192.168.5.163/api/v3 를 사용하세요.',
      );
    }
  }

  String get API_HOST => apiHost;
}
