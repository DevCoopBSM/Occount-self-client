import 'package:counter/ui/_constant/theme/devcoop_colors.dart';
import 'package:counter/ui/_constant/theme/devcoop_text_style.dart';
import 'package:flutter/material.dart';

GestureDetector mainTextButton({
  required dynamic text,
  bool isButtonDisabled = false, // 기본값 설정
  required Function()? onTap,
  Color? color,
}) {
  return GestureDetector(
    onTap: isButtonDisabled ? null : onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          10,
        ),
        color: isButtonDisabled
            ? Colors.grey
            : DevCoopColors.primary, // 비활성화 상태일 때 색상 변경
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            color: DevCoopColors.black.withOpacity(
              0.25,
            ),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: text is String
          ? Text(
              text,
              style: DevCoopTextStyle.bold_30.copyWith(
                color: DevCoopColors.black,
                fontSize: 24,
              ),
            )
          : text,
    ),
  );
}
