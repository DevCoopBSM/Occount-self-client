import 'package:counter/ui/_constant/theme/devcoop_colors.dart';
import 'package:counter/ui/_constant/theme/devcoop_text_style.dart';
import 'package:counter/ui/_constant/util/number_format_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 결제 진행 중 팝업
Widget paymentProcessingPopup(
  BuildContext context, {
  required String title,
  required String message,
  String? cardAmount,
}) {
  return AlertDialog(
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        if (cardAmount != null) ...[
          const SizedBox(height: 20),
          Text(
            cardAmount,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: DevCoopColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        const LinearProgressIndicator(
          backgroundColor: DevCoopColors.grey,
          valueColor: AlwaysStoppedAnimation<Color>(DevCoopColors.primary),
        ),
      ],
    ),
  );
}

// 결제 결과 팝업
Widget paymentResultPopup(
  BuildContext context,
  String message,
  bool isError, {
  bool isCharge = false,
  int? totalAmount,
  int? remainingPoints,
}) {
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
          if (totalAmount != null && remainingPoints != null && !isError) ...[
            Text(
              "결제금액: ${NumberFormatUtil.convert1000Number(totalAmount)}원",
              style: DevCoopTextStyle.light_40.copyWith(
                color: DevCoopColors.black,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "잔여금액: ${NumberFormatUtil.convert1000Number(remainingPoints)}원",
              style: DevCoopTextStyle.light_40.copyWith(
                color: DevCoopColors.black,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ] else
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
          if (isCharge)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "확인",
                style: DevCoopTextStyle.medium_30.copyWith(
                  color: DevCoopColors.primary,
                ),
              ),
            )
          else
            Text(
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
