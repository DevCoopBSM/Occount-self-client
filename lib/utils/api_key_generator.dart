import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

class ApiKeyGenerator {
  final String secretKey;
  static const int timeWindow = 300;
  final Logger _logger = Logger('ApiKeyGenerator');

  ApiKeyGenerator({required String secretKey})
      : secretKey = secretKey.endsWith('}')
            ? secretKey.substring(0, secretKey.length - 1)
            : secretKey;

  String generateApiKey() {
    try {
      final currentTime = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final timeCounter = currentTime ~/ timeWindow;

      final hmac = Hmac(sha256, utf8.encode(secretKey));
      final digest = hmac.convert(utf8.encode(timeCounter.toString()));

      return digest.bytes.map((byte) {
        return (byte & 0xFF).toRadixString(16).padLeft(2, '0');
      }).join();
    } catch (e) {
      _logger.severe('API 키 생성 중 오류 발생: $e');
      rethrow;
    }
  }

  bool isValidApiKey(String requestApiKey) {
    try {
      final currentTime = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

      for (int offset = -1; offset <= 1; offset++) {
        final timestamp = currentTime + (offset * timeWindow);
        final timeCounter = timestamp ~/ timeWindow;

        final hmac = Hmac(sha256, utf8.encode(secretKey));
        final digest = hmac.convert(utf8.encode(timeCounter.toString()));

        final expectedKey = digest.bytes.map((byte) {
          return (byte & 0xFF).toRadixString(16).padLeft(2, '0');
        }).join();

        if (requestApiKey == expectedKey) {
          return true;
        }
      }
      return false;
    } catch (e) {
      _logger.severe('API 키 검증 중 오류 발생: $e');
      return false;
    }
  }
}
