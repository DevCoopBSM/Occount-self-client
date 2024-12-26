import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

class ApiKeyGenerator {
  final String secretKey;
  static const int timeWindow = 300; // 5분
  final Logger _logger = Logger('ApiKeyGenerator');

  ApiKeyGenerator({required this.secretKey});

  String generateApiKey() {
    try {
      final currentTime = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final timeCounter = currentTime ~/ timeWindow;

      _logger.info('''
===== API 키 생성 시작 =====
현재 UTC 시간: ${DateTime.now().toUtc()}
타임스탬프 (초): $currentTime
시간 카운터: $timeCounter
사용된 비밀키: $secretKey
비밀키 바이트: ${utf8.encode(secretKey)}
메시지: ${timeCounter.toString()}
메시지 바이트: ${utf8.encode(timeCounter.toString())}
''');

      final hmac = Hmac(sha256, utf8.encode(secretKey));
      final digest = hmac.convert(utf8.encode(timeCounter.toString()));

      final hexString = digest.bytes.map((byte) {
        return (byte & 0xFF).toRadixString(16).padLeft(2, '0');
      }).join();

      _logger.info('''
HMAC 바이트: ${digest.bytes}
생성된 키: $hexString
''');
      return hexString;
    } catch (e) {
      _logger.severe('API 키 생성 중 오류 발생: $e');
      rethrow;
    }
  }

  bool isValidApiKey(String requestApiKey) {
    try {
      final currentTime = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

      _logger.info('''
===== API 키 검증 시작 =====
수신된 API 키: $requestApiKey
현재 UTC 시간: ${DateTime.now().toUtc()}
타임스탬프 (초): $currentTime
사용된 비밀키: $secretKey
''');

      for (int offset = -1; offset <= 1; offset++) {
        final timestamp = currentTime + (offset * timeWindow);
        final timeCounter = timestamp ~/ timeWindow;

        _logger.info('검증 시도 [$offset] - 타임스탬프: $timestamp, 카운터: $timeCounter');

        final hmac = Hmac(sha256, utf8.encode(secretKey));
        final digest = hmac.convert(utf8.encode(timeCounter.toString()));

        final expectedKey = digest.bytes.map((byte) {
          return (byte & 0xFF).toRadixString(16).padLeft(2, '0');
        }).join();

        _logger.info('기대되는 키 [$offset]: $expectedKey');

        if (requestApiKey == expectedKey) {
          _logger.info('API 키 일치 - 오프셋: $offset');
          return true;
        }
      }

      _logger.warning('모든 시간 윈도우에서 API 키 불일치');
      return false;
    } catch (e) {
      _logger.severe('API 키 검증 중 오류 발생: $e');
      return false;
    }
  }
}
