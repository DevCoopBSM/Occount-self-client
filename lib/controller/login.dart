import 'dart:convert';
import 'package:counter/controller/save_user_info.dart';
import 'package:counter/secure/db.dart';
import 'package:counter/ui/_constant/theme/devcoop_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LoginController {
  final dbSecure = DbSecure();

  Future<void> login(
      BuildContext context, String userCode, String userPin) async {
    Map<String, String> requestBody = {
      'userCode': userCode,
      'userPin': userPin
    };

    String jsonData = json.encode(requestBody);
    String apiUrl = 'http://localhost:8080/kiosk/auth/signIn'; // 실제 서버 주소로 변경

    try {
      // 로딩 인디케이터 표시
      Get.dialog(
          const Center(
            child: CircularProgressIndicator(
              color: DevCoopColors.primary,
              strokeWidth: 5,
            ),
          ),
          barrierDismissible: false);

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonData,
      );

      Get.back(); // 로딩 인디케이터 닫기

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 응답 본문을 UTF-8로 디코딩
        Map<String, dynamic> responseBody =
            json.decode(utf8.decode(response.bodyBytes));

        // 메시지와 리다이렉션 URL을 처리
        if (responseBody['message'] == '안전하지 않은 비밀번호입니다. 비밀번호를 변경해주세요') {
          final String redirectUrl = responseBody['redirectUrl'] ?? '/';

          // 팝업창 띄우기
          Get.dialog(
            AlertDialog(
              title: const Text(
                "경고",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: DevCoopColors.error),
              ),
              content: const Text(
                "초기 핀 번호는 안전하지 않은 비밀번호입니다. 핀 변경 페이지로 이동합니다",
                style: TextStyle(
                    fontSize: 16,
                    color: DevCoopColors.black,
                    fontWeight: FontWeight.w700),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Get.back(); // 팝업 닫기
                    Get.offAllNamed(redirectUrl); // 리다이렉션
                  },
                  child: const Text(
                    "확인",
                    style: TextStyle(color: DevCoopColors.black),
                  ),
                ),
              ],
            ),
          );
          return; // 리다이렉션 후 함수 종료
        }

        String token = responseBody['token'] ?? '';
        String userName = responseBody['userName'] ?? '';
        int userPoint = responseBody['userPoint'] ?? 0;

        saveUserData(token, userCode, userPoint, userName);
        Get.offAllNamed('/check');
      } else {
        Get.snackbar("Error", "학생증 번호 또는 핀 번호가 잘못되었습니다",
            colorText: Colors.white,
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2));
      }
    } catch (e) {
      Get.snackbar("Error", "로그인 중 오류가 발생했습니다: $e",
          colorText: Colors.white,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2));
    }
  }
}
