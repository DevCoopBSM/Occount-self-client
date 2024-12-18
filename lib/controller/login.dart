import 'dart:convert';
import 'package:counter/secure/db.dart';
import 'package:counter/ui/_constant/theme/devcoop_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:counter/controller/user_controller.dart';
import 'package:logging/logging.dart';

class LoginController extends GetxController {
  final dbSecure = DbSecure();
  final _logger = Logger('LoginController');
  final RxBool isLoading = false.obs;

  Future<void> login(
      String userCode, String userPin, BuildContext context) async {
    if (isLoading.value) return;

    try {
      isLoading(true);
      _logger.info('🔑 로그인 시도: $userCode');

      // 로딩 인디케이터 표시
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            color: DevCoopColors.primary,
            strokeWidth: 5,
          ),
        ),
        barrierDismissible: false,
      );

      final response = await http.post(
        Uri.parse('${dbSecure.DB_HOST}/kiosk/auth/signIn'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: json.encode({
          'userCode': userCode,
          'userPin': userPin,
        }),
      );

      Get.back(); // 로딩 인디케이터 닫기

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));

        // 안전하지 않은 비밀번호 처리
        if (responseBody['message'] == '안전하지 않은 비밀번호입니다. 비밀번호를 변경해주세요') {
          _handleUnsafePassword(responseBody['redirectUrl'] ?? '/');
          return;
        }

        // 정상 로그인 처리
        if (response.statusCode == 200) {
          String accessToken = responseBody['token'] ?? '';
          String userName = responseBody['userName'] ?? '';
          int userPoint = responseBody['userPoint'] ?? 0;

          // UserController를 통해 사용자 정보 저장
          final userController = Get.find<UserController>();
          userController.setUserData(
            userName,
            userPoint,
            userCode,
            accessToken,
          );

          Get.offAllNamed('/check');
        }
      } else {
        Get.snackbar(
          "로그인 실패",
          "학생증 번호 또는 핀 번호가 잘못되었습니다",
          colorText: Colors.white,
          backgroundColor: DevCoopColors.error,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      _logger.severe('❌ 로그인 실패', e);
      Get.snackbar(
        "로그인 실패",
        "로그인 중 오류가 발생했습니다",
        colorText: Colors.white,
        backgroundColor: DevCoopColors.error,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading(false);
    }
  }

  void _handleUnsafePassword(String redirectUrl) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          "경고",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: DevCoopColors.error,
          ),
        ),
        content: const Text(
          "초기 핀 번호는 안전하지 않은 비밀번호입니다. 핀 변경 페이지로 이동합니다",
          style: TextStyle(
            fontSize: 16,
            color: DevCoopColors.black,
            fontWeight: FontWeight.w700,
          ),
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
  }
}
