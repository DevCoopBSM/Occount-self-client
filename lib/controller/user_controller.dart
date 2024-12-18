import 'package:get/get.dart';
import 'package:logging/logging.dart';
import '../models/user_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserController extends GetxController {
  final Rx<UserInfo> user = UserInfo(point: 0, name: '', code: '').obs;
  final RxBool isLoggedIn = false.obs;
  final _logger = Logger('UserController');

  @override
  void onInit() {
    super.onInit();
    loadUserFromStorage();
  }

  Future<void> loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName') ?? '';
      final userPoint = prefs.getInt('userPoint') ?? 0;
      final userCode = prefs.getString('userCode') ?? '';
      final token = prefs.getString('accessToken');

      if (token != null && token.isNotEmpty) {
        user.update((val) {
          val?.name = userName;
          val?.point = userPoint;
          val?.code = userCode;
        });
        isLoggedIn.value = true;
      }
    } catch (e) {
      _logger.severe('Error loading user data: $e');
    }
  }

  Future<void> setUserData(
      String name, int point, String code, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      await prefs.setInt('userPoint', point);
      await prefs.setString('userCode', code);
      await prefs.setString('accessToken', token);

      user.update((val) {
        val?.name = name;
        val?.point = point;
        val?.code = code;
      });
      isLoggedIn.value = true;
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  void updateUserPoint(int newPoint) {
    user.update((val) {
      val?.point = newPoint;
    });
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      user.value = UserInfo(point: 0, name: '', code: '');
      isLoggedIn.value = false;
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
