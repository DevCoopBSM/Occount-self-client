class DbSecure {
  final String dbHost;

  DbSecure() : dbHost = 'https://kiosk.bsm-aripay.kr';

  // DB_HOST getter 추가
  // ignore: non_constant_identifier_names
  String get DB_HOST => dbHost;
}
