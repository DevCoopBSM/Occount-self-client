class ApiConfig {
  final String apiHost;
  final String apiKey;

  ApiConfig()
      : apiHost = const String.fromEnvironment('API_HOST',
            defaultValue: 'https://kiosk.bsm-aripay.kr'),
        apiKey = const String.fromEnvironment('API_KEY', defaultValue: '');

  String get API_HOST => apiHost;
  String get API_KEY => apiKey;
}
