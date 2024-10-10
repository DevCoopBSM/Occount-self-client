import 'package:shared_preferences/shared_preferences.dart';

Future<void> loadUserData(
  Function setState,
  int savedPoint,
  String savedStudentName,
  String savedCodeNumber,
  String token,
) async {
  try {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      savedPoint = sharedPreferences.getInt('userPoint') ?? 0;
      savedStudentName = sharedPreferences.getString('userName') ?? '';
      savedCodeNumber = sharedPreferences.getString('userCode') ?? '';
      token = sharedPreferences.getString('accessToken') ?? '';
    });
  } catch (e) {
    rethrow;
  }
}
