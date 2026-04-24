import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../services/auth_service.dart';
import '../services/kiosk_config_service.dart';
import '../exception/api_exception.dart';
import '../models/user_info.dart';
import '../models/auth_response.dart';
import '../models/login_result.dart';
import '../models/cart_item.dart';
import '../main.dart';
import '../ui/components/session_expired_dialog.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final KioskConfigService _kioskConfigService;
  final Logger _logger = Logger('AuthProvider');
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;
  bool _isGuestMode = false;
  bool _isGuestCheckoutOnlyEnabled = false;
  final List<CartItem> _cartItems = [];

  final UserInfo _emptyUserInfo = UserInfo(
    userCode: '',
    userName: '',
    userNumber: '',
    userPoint: 0,
  );

  UserInfo _userInfo = UserInfo(
    userCode: '',
    userName: '',
    userNumber: '',
    userPoint: 0,
  );

  final UserInfo _guestUserInfo = UserInfo(
    userCode: 'GUEST',
    userName: '게스트',
    userNumber: '',
    userPoint: 0,
  );

  static const int sessionTimeoutSeconds = 300;
  Timer? _sessionTimer;
  bool _isSessionExpired = false;

  AuthProvider(this._authService, this._kioskConfigService) {
    _initialize();
  }

  bool get isSessionExpired => _isSessionExpired;

  bool get isLoading => _isLoading;
  String? get error => _error;
  UserInfo get userInfo => _userInfo;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuestMode => _isGuestMode;
  bool get isGuestCheckoutOnlyEnabled => _isGuestCheckoutOnlyEnabled;
  List<CartItem> get cartItems => _cartItems;

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final enabled = await _kioskConfigService.isGuestModeEnabled();
      _isGuestCheckoutOnlyEnabled = enabled;

      if (enabled) {
        _activateGuestMode(notify: false);
      } else {
        _userInfo = _emptyUserInfo;
      }
    } catch (e) {
      _logger.severe('❌ 초기 게스트 모드 설정 로드 실패: $e');
      _isGuestCheckoutOnlyEnabled = false;
      _userInfo = _emptyUserInfo;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _activateGuestMode({bool notify = true}) {
    _cancelSessionTimer();
    _isGuestMode = true;
    _isLoggedIn = false;
    _isSessionExpired = false;
    _error = null;
    _userInfo = _guestUserInfo;

    if (notify) {
      notifyListeners();
    }
  }

  Future<LoginResult> login(String codeNumber, String pin) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Step 1: 토큰만 획득 (빠른 화면 전환)
      final token = await _authService.loginForToken(codeNumber, pin);

      // userCode 저장 (accessToken은 loginForToken에서 이미 저장됨)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userCode', codeNumber);

      _userInfo = UserInfo(
        userCode: codeNumber,
        userName: '',
        userNumber: '',
        userPoint: 0,
      );
      _isLoggedIn = true;
      _isLoading = false;
      _startSessionTimer();
      notifyListeners();

      // 백그라운드에서 사용자 정보(이름, 포인트) 로드
      _loadUserInfoInBackground(codeNumber);

      return LoginResult(success: true);
    } catch (e) {
      _isLoading = false;
      _logger.severe('❌ login() catch (타입: ${e.runtimeType}): $e');

      if (e is ApiException) {
        _logger.severe(
            '❌ ApiException - code: ${e.code}, message: ${e.message}, status: ${e.status}');

        if (e.code.code == 'DEFAULT_PIN_IN_USE') {
          // code.code로 정확한 에러 코드 비교
          _error = e.code.code; // 원본 에러 코드 저장
          notifyListeners();
          return LoginResult(
            success: false,
            message: e.message,
            redirectUrl: null,
          );
        }

        _error = e.message;
        notifyListeners();
        return LoginResult(success: false, message: e.message);
      }

      _error = '네트워크 오류가 발생했습니다';
      notifyListeners();
      return LoginResult(success: false, message: _error);
    }
  }

  /// 백그라운드에서 사용자 이름과 포인트를 비동기 로드
  Future<void> _loadUserInfoInBackground(String userBarcode) async {
    try {
      final userInfo = await _authService.fetchUserInfo(userBarcode);

      // SharedPreferences에도 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', userInfo.userName);
      await prefs.setInt('userPoint', userInfo.userPoint);

      _userInfo = userInfo;
      notifyListeners();

      _logger.info('✅ 백그라운드 사용자 정보 로드 완료: ${userInfo.userName}');
    } catch (e) {
      _logger.severe('❌ 백그라운드 사용자 정보 로드 실패: $e');
      // 사용자에게 알리지 않음 — 바코드 스캔은 계속 가능
    }
  }

  Future<void> _saveUserData(AuthResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', response.token);
    await prefs.setString('userCode', response.userInfo.userCode);
    await prefs.setString('userName', response.userInfo.userName);
    await prefs.setInt('userPoint', response.userInfo.userPoint);
    await prefs.setString('userNumber', response.userInfo.userNumber);

    _userInfo = response.userInfo;
    _isLoggedIn = true;
    _isLoading = false;
    _startSessionTimer();
    notifyListeners();
  }

  void _startSessionTimer() {
    _cancelSessionTimer();
    _isSessionExpired = false;
    _sessionTimer = Timer(const Duration(seconds: sessionTimeoutSeconds), () {
      _logger.info('[AUTH] 세션 타이머 만료 ($sessionTimeoutSeconds초)');
      _isSessionExpired = true;
      _showSessionExpiredDialog();
    });
  }

  void pauseSessionTimer() {
    _cancelSessionTimer();
  }

  void _cancelSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _showSessionExpiredDialog() {
    final context = globalNavigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SessionExpiredDialog(
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          await logout();
          globalNavigatorKey.currentState
              ?.pushNamedAndRemoveUntil('/', (route) => false);
        },
      ),
    );
  }

  void updateUserPoint(int newPoint) {
    _userInfo = UserInfo(
      userCode: _userInfo.userCode,
      userName: _userInfo.userName,
      userNumber: _userInfo.userNumber,
      userPoint: newPoint,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      _cancelSessionTimer();
      final prefs = await SharedPreferences.getInstance();

      // 키오스크 ID는 보존하고 인증 관련 데이터만 선택적으로 삭제
      final kioskId = prefs.getString('kiosk_id');

      // 인증 관련 키들만 삭제 (키오스크 ID는 보존)
      await prefs.remove('accessToken');
      await prefs.remove('userCode');
      await prefs.remove('userName');
      await prefs.remove('userPoint');
      await prefs.remove('userNumber');

      _logger.info('🏪 [AUTH] 로그아웃 완료 - 키오스크 ID 보존: ${kioskId ?? "NULL"}');
      resetState();
    } catch (e) {
      _logger.severe('Error during logout: $e');
    }
  }

  Future<void> returnToLanding() async {
    try {
      _cancelSessionTimer();
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('accessToken');
      await prefs.remove('userCode');
      await prefs.remove('userName');
      await prefs.remove('userPoint');
      await prefs.remove('userNumber');

      _isLoading = false;
      _error = null;
      _isLoggedIn = false;
      _isSessionExpired = false;
      _cartItems.clear();

      if (_isGuestCheckoutOnlyEnabled) {
        _isGuestMode = true;
        _userInfo = _guestUserInfo;
      } else {
        _isGuestMode = false;
        _userInfo = _emptyUserInfo;
      }
      notifyListeners();
    } catch (e) {
      _logger.severe('Error while returning to landing: $e');
    }
  }

  // validatePin() 제거 — 명세서에서 해당 엔드포인트 삭제됨

  Future<void> updatePoint() async {
    try {
      // 명세서 변경: getPoint()는 path param 없음 (토큰 기반)
      final updatedPoint = await _authService.getPoint();
      if (updatedPoint != null) {
        _userInfo = UserInfo(
          userCode: _userInfo.userCode,
          userName: _userInfo.userName,
          userNumber: _userInfo.userNumber,
          userPoint: updatedPoint,
        );
        notifyListeners();
      }
    } catch (e) {
      _logger.severe('포인트 업데이트 실패: $e');
      rethrow;
    }
  }

  Future<void> fetchUserPoints(String userCode) async {
    // API 호출 등을 통해 포인트 정보를 가져오는 로직
    // _points = await _userService.getUserPoints(userCode);
    notifyListeners();
  }

  void addToCart(CartItem item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _cartItems.remove(item);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  void resetState() {
    _cancelSessionTimer();
    _isLoading = false;
    _error = null;
    _isLoggedIn = false;
    _isSessionExpired = false;
    _cartItems.clear();

    if (_isGuestCheckoutOnlyEnabled) {
      _isGuestMode = true;
      _userInfo = _guestUserInfo;
    } else {
      _isGuestMode = false;
      _userInfo = _emptyUserInfo;
    }

    notifyListeners();
  }

  void enableGuestMode() {
    _activateGuestMode();
  }

  void setGuestCheckoutOnlyEnabled(bool enabled) {
    _isGuestCheckoutOnlyEnabled = enabled;

    if (enabled) {
      _activateGuestMode();
      return;
    }

    resetState();
  }

  void increaseQuantity(int itemId) {
    final index = _cartItems.indexWhere((item) => item.itemId == itemId);
    if (index != -1) {
      _cartItems[index].quantity++;
      notifyListeners();
    }
  }

  void decreaseQuantity(int itemId) {
    final index = _cartItems.indexWhere((item) => item.itemId == itemId);
    if (index != -1) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }
}
