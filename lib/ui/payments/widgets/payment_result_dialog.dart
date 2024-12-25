import 'dart:async';
import 'package:flutter/material.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';
import '../../_constant/util/number_format_util.dart';
import '../../_constant/component/button.dart';
import '../../../models/payment_response.dart';
import '../../../provider/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../utils/sound_utils.dart';

class PaymentResultDialog extends StatefulWidget {
  final PaymentResponse? response;
  final String? errorMessage;
  final bool isSuccess;
  final bool shouldReturnToHome;
  final String? errorCode;

  const PaymentResultDialog({
    Key? key,
    this.response,
    this.errorMessage,
    required this.isSuccess,
    this.shouldReturnToHome = true,
    this.errorCode,
  }) : super(key: key);

  @override
  State<PaymentResultDialog> createState() => _PaymentResultDialogState();
}

class _PaymentResultDialogState extends State<PaymentResultDialog> {
  static const int _totalSeconds = 3;
  Timer? _timer;
  double _progress = 0.0;
  int remainingSeconds = _totalSeconds;
  bool _isFirstBuild = true;

  String get resultMessage {
    if (!widget.isSuccess) {
      if (widget.errorCode == 'PAYMENT_TIMEOUT') {
        return '결제 시간이 초과되었습니다.\n다시 시도해주세요.';
      }
      return widget.errorMessage ?? '결제 처리 중 오류가 발생했습니다';
    }

    if (widget.response == null) {
      return '결제가 완료되었습니다';
    }

    final response = widget.response!;
    String message = '결제가 완료되었습니다\n\n';
    message +=
        '결제금액: ${NumberFormatUtil.convert1000Number(response.totalAmount)}원\n';

    if (response.chargedAmount > 0) {
      message +=
          '충전금액: ${NumberFormatUtil.convert1000Number(response.chargedAmount)}원\n';
    }

    message +=
        '잔여포인트: ${NumberFormatUtil.convert1000Number(response.remainingPoints)}원';

    if (response.approvalNumber.isNotEmpty) {
      message += '\n승인번호: ${response.approvalNumber}';
    }

    return message;
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    const duration = Duration(milliseconds: 50);
    const totalSteps = _totalSeconds * 1000 ~/ 50;

    _timer = Timer.periodic(duration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _progress = (timer.tick / totalSteps).clamp(0.0, 1.0);
        remainingSeconds = (_totalSeconds * (1.0 - _progress)).ceil();

        if (_progress >= 1.0) {
          timer.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.resetState();
    authProvider.logout();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.isSuccess) {
          SoundUtils.playSound(SoundType.success);
        } else {
          SoundUtils.playSound(SoundType.error);
        }
      });
    }

    return AlertDialog(
      title: Text(
        widget.isSuccess ? '결제 완료' : '결제 실패',
        style: DevCoopTextStyle.bold_30.copyWith(
          color: widget.isSuccess ? Colors.green : Colors.red,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isSuccess ? Icons.check_circle : Icons.error,
            size: 48,
            color: widget.isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            resultMessage,
            style: DevCoopTextStyle.medium_30,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: 1.0 - _progress,
            backgroundColor: DevCoopColors.grey,
            valueColor:
                const AlwaysStoppedAnimation<Color>(DevCoopColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '$remainingSeconds초 후 초기화면으로 이동합니다',
              style: DevCoopTextStyle.medium_20,
            ),
          ),
        ],
      ),
      actions: [
        if (!widget.isSuccess)
          MainTextButton(
            text: '장바구니로',
            onTap: () {
              _timer?.cancel();
              Navigator.of(context).pop();
            },
            color: DevCoopColors.primary,
          ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
