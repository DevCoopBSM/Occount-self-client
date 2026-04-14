import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

class KioskConfigService {
  static const String _kioskIdKey = 'kiosk_id';
  final Logger _logger = Logger('KioskConfigService');

  /// 저장된 키오스크 ID 조회
  Future<String?> getKioskId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kioskId = prefs.getString(_kioskIdKey);
      _logger.info('🏪 [KIOSK_CONFIG] 키오스크 ID 조회: $kioskId');
      return kioskId;
    } catch (e) {
      _logger.severe('❌ [KIOSK_CONFIG] 키오스크 ID 조회 실패: $e');
      return null;
    }
  }

  /// 키오스크 ID 저장
  Future<bool> saveKioskId(String kioskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_kioskIdKey, kioskId);
      _logger.info('🏪 [KIOSK_CONFIG] 키오스크 ID 저장 성공: $kioskId');
      return success;
    } catch (e) {
      _logger.severe('❌ [KIOSK_CONFIG] 키오스크 ID 저장 실패: $e');
      return false;
    }
  }

  /// 키오스크 ID 삭제
  Future<bool> clearKioskId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_kioskIdKey);
      _logger.info('🏪 [KIOSK_CONFIG] 키오스크 ID 삭제 완료');
      return success;
    } catch (e) {
      _logger.severe('❌ [KIOSK_CONFIG] 키오스크 ID 삭제 실패: $e');
      return false;
    }
  }

  /// 키오스크 ID가 설정되어 있는지 확인
  Future<bool> hasKioskId() async {
    final kioskId = await getKioskId();
    return kioskId != null && kioskId.isNotEmpty;
  }
}