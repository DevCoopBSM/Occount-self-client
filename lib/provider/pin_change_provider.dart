import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../exception/api_exception.dart';

class PinChangeProvider with ChangeNotifier {
  final AuthService _authService;
  bool _isLoading = false;
  String? _error;

  PinChangeProvider(this._authService);

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> changePinNumber(
    String userCode,
    String currentPin,
    String newPin,
    BuildContext context,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 명세서에서 changePin 엔드포인트 제거됨 — 기능 비활성화
      // 추후 해당 기능이 필요하면 서버 팀에 새 엔드포인트 추가 요청 필요
      throw ApiException(
        code: ApiErrorCode.changePinFailed,
        message: '핀번호 변경 기능은 현재 지원하지 않습니다',
        status: '501',
      );

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('핀번호가 변경되었습니다')),
        );
      }
      return true;
    } catch (e) {
      _error = e is ApiException ? e.message : '핀번호 변경에 실패했습니다';
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error ?? '알 수 없는 오류가 발생했습니다')),
        );
      }
      return false;
    }
  }
}
