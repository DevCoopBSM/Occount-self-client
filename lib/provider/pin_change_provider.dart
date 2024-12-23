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

      await _authService.changePin(userCode, currentPin, newPin);

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
