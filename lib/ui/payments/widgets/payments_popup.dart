import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:counter/ui/_constant/theme/devcoop_colors.dart';
import 'package:counter/ui/_constant/theme/devcoop_text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void navigateToNextPage() {
  Get.offAllNamed('/');
}

Future<void> removeUserData() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('codeNumber');
    prefs.remove('pin');
    prefs.remove('point');
    prefs.remove('studentName');
  } catch (e) {
    rethrow;
  }
}

Widget paymentsPopUp(BuildContext context, String message, bool isError,
    {bool isCharge = false}) {
  if (!isCharge) {
    // 결제 팝업인 경우
    Future.delayed(const Duration(seconds: 3), () {
      navigateToNextPage();
      AssetsAudioPlayer.newPlayer().open(
        Audio('assets/audio/finish.wav'),
        showNotification: true,
        autoStart: true,
      );
    });
  }

  return AlertDialog(
    content: Container(
      width: 520,
      constraints: const BoxConstraints(maxHeight: 320),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isCharge
                ? (isError ? "충전 실패" : "충전 성공")
                : (isError ? "결제 실패" : "결제 성공"),
            style: DevCoopTextStyle.bold_40.copyWith(
              color: isError ? DevCoopColors.error : DevCoopColors.success,
              fontSize: 30,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                message,
                style: DevCoopTextStyle.light_40.copyWith(
                  color: DevCoopColors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 20),
          isCharge
              ? TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 충전의 경우 팝업만 닫기
                  },
                  child: Text(
                    "확인",
                    style: DevCoopTextStyle.medium_30.copyWith(
                      color: DevCoopColors.primary,
                    ),
                  ),
                )
              : Text(
                  "잠시후에 처음화면으로 돌아갑니다",
                  style: DevCoopTextStyle.medium_30.copyWith(
                    color: DevCoopColors.black,
                  ),
                ),
        ],
      ),
    ),
  );
}
