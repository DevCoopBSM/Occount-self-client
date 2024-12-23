import 'dart:async';
import 'package:flutter/material.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';
import '../../_constant/util/number_format_util.dart';
import '../../_constant/component/button.dart';
import '../../../models/payment_response.dart';
import '../../../provider/auth_provider.dart';
import '../../../main.dart';
import 'package:provider/provider.dart';
import '../../../ui/login/barcode_scan_page.dart';

class PaymentResultDialog extends StatefulWidget {
  final PaymentResponse? response;
  final String? errorMessage;

  const PaymentResultDialog({
    Key? key,
    this.response,
    this.errorMessage,
  }) : super(key: key);

  bool get isError => response == null;

  @override
  State<PaymentResultDialog> createState() => _PaymentResultDialogState();
}

class _PaymentResultDialogState extends State<PaymentResultDialog> {
  Timer? _timer;
  bool _showRetryButton = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.resetState();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BarcodeScanPage()),
            (route) => false,
          );
        }
      }
    });
  }

  void _cancelTimerAndClose() {
    _timer?.cancel();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScanPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isError ? '결제 실패' : '결제 완료',
              style: DevCoopTextStyle.bold_40.copyWith(
                color: widget.isError
                    ? DevCoopColors.error
                    : DevCoopColors.success,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!widget.isError && widget.response != null) ...[
              Text(
                '총 결제금액: ${NumberFormatUtil.convert1000Number(widget.response!.totalAmount)}원',
                style: DevCoopTextStyle.bold_30,
              ),
              const SizedBox(height: 10),
              Text(
                '잔여 포인트: ${NumberFormatUtil.convert1000Number(widget.response!.remainingPoints)}원',
                style: DevCoopTextStyle.medium_30,
              ),
            ] else ...[
              Text(
                widget.errorMessage ?? '결제 처리 중 오류가 발생했습니다',
                style: DevCoopTextStyle.medium_30,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            if (widget.isError && _showRetryButton)
              mainTextButton(
                text: "다시 결제하기",
                onTap: _cancelTimerAndClose,
                color: DevCoopColors.primary,
              ),
            const SizedBox(height: 20),
            Text(
              "2초 후 초기 화면으로 돌아갑니다",
              style: DevCoopTextStyle.medium_30.copyWith(
                color: DevCoopColors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
