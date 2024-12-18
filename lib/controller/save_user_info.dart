import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveUserData(
    String accessToken, String userCode, int userPoint, String userName) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('userCode', userCode);
    await prefs.setInt('userPoint', userPoint);
    await prefs.setString('userName', userName);
  } catch (e) {
    print('Error saving user data: $e');
    rethrow;
  }
}
