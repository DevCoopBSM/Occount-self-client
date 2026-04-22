import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_info.dart';
import '../../../provider/auth_provider.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';
import '../../_constant/util/number_format_util.dart';

class PaymentHeader extends StatefulWidget {
  final UserInfo? userInfo;

  const PaymentHeader({
    Key? key,
    required this.userInfo,
  }) : super(key: key);

  @override
  State<PaymentHeader> createState() => _PaymentHeaderState();
}

class _PaymentHeaderState extends State<PaymentHeader> {
  Timer? _adminTimer;

  @override
  void dispose() {
    _adminTimer?.cancel();
    super.dispose();
  }

  void _onNameLongPressStart(LongPressStartDetails _) {
    _adminTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushNamed(context, '/admin');
      }
    });
  }

  void _cancelAdminTimer() {
    _adminTimer?.cancel();
    _adminTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: DevCoopColors.white,
            boxShadow: [
              BoxShadow(
                color: DevCoopColors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onLongPressStart: _onNameLongPressStart,
                onLongPressEnd: (_) => _cancelAdminTimer(),
                onLongPressCancel: _cancelAdminTimer,
                child: Text(
                  authProvider.isGuestMode
                      ? '게스트님'
                      : '${widget.userInfo?.userName}님',
                  style: DevCoopTextStyle.medium_30,
                ),
              ),
              Text(
                authProvider.isGuestMode
                    ? '게스트 모드 (포인트 사용 불가)'
                    : '아리페이 잔액: ${NumberFormatUtil.convert1000Number(widget.userInfo?.userPoint ?? 0)}원',
                style: DevCoopTextStyle.medium_30,
              ),
            ],
          ),
        );
      },
    );
  }
}
