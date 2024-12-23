import 'package:flutter/material.dart';
import '../../../models/user_info.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';
import '../../_constant/util/number_format_util.dart';

class PaymentHeader extends StatelessWidget {
  final UserInfo? userInfo;

  const PaymentHeader({
    Key? key,
    required this.userInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: DevCoopColors.white,
        boxShadow: [
          BoxShadow(
            color: DevCoopColors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (userInfo == null)
            const Text(
              '로그인이 필요합니다',
              style: DevCoopTextStyle.medium_30,
            )
          else
            Text(
              '${userInfo?.userName}님',
              style: DevCoopTextStyle.medium_30,
            ),
          Text(
            '아리페이 잔액: ${NumberFormatUtil.convert1000Number(userInfo?.userPoint ?? 0)}원',
            style: DevCoopTextStyle.medium_30,
          ),
        ],
      ),
    );
  }
}
