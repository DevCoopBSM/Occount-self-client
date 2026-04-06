import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../services/auth_service.dart';
import '../exception/api_exception.dart';
import '../models/user_info.dart';
import '../models/auth_response.dart';
import '../models/login_result.dart';
import '../models/cart_item.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final Logger _logger = Logger('AuthProvider');
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;
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

  AuthProvider(this._authService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  UserInfo get userInfo => _userInfo;
  bool get isLoggedIn => _isLoggedIn;
  List<CartItem> get cartItems => _cartItems;

  Future<LoginResult> login(String codeNumber, String pin) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _authService.login(codeNumber, pin);
      await _saveUserData(response);
      return LoginResult(success: true);
    } catch (e) {
      _isLoading = false;

      if (e is ApiException) {

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
    notifyListeners();
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      resetState();
    } catch (e) {
      _logger.severe('Error during logout: $e');
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
    _isLoading = false;
    _error = null;
    _isLoggedIn = false;
    _userInfo = _emptyUserInfo;
    _cartItems.clear();
    notifyListeners();
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
