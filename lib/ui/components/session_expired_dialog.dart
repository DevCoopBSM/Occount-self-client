import 'package:flutter/material.dart';

import '../_constant/component/button.dart';
import '../_constant/theme/devcoop_colors.dart';
import '../_constant/theme/devcoop_text_style.dart';

class SessionExpiredDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const SessionExpiredDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        child: Container(
          width: 520,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time_filled_rounded,
                size: 56,
                color: DevCoopColors.error,
              ),
              const SizedBox(height: 20),
              Text(
                '세션 만료',
                style: DevCoopTextStyle.bold_40.copyWith(
                  color: DevCoopColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '결제 제한시간이 지났습니다.\n다시 로그인 해주세요.',
                style: DevCoopTextStyle.medium_30,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              MainTextButton(
                text: '확인',
                onTap: onConfirm,
                color: DevCoopColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
