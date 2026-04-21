import 'package:flutter/material.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';
import '../../_constant/util/number_format_util.dart';

class PaymentProcessingDialog extends StatefulWidget {
  final int totalAmount;
  final int paymentAmount;
  final int cardAmount;
  final bool isChargeOnly;
  final bool hasCharge;
  final VoidCallback onClose;

  const PaymentProcessingDialog({
    Key? key,
    required this.totalAmount,
    required this.paymentAmount,
    required this.cardAmount,
    required this.isChargeOnly,
    required this.hasCharge,
    required this.onClose,
  }) : super(key: key);

  @override
  State<PaymentProcessingDialog> createState() =>
      _PaymentProcessingDialogState();
}

class _PaymentProcessingDialogState extends State<PaymentProcessingDialog> {
  bool _isCancelPressed = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isChargeOnly
                    ? '충전 진행 중'
                    : widget.hasCharge
                        ? '충전 및 결제 진행 중'
                        : '결제 진행 중',
                style: DevCoopTextStyle.bold_40.copyWith(
                  color: widget.isChargeOnly
                      ? const Color.fromARGB(255, 0, 255, 89)
                      : widget.hasCharge
                          ? const Color.fromARGB(255, 0, 0, 255)
                          : DevCoopColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.hasCharge && !widget.isChargeOnly) ...[
                const SizedBox(height: 8),
                const Text(
                  '충전과 상품결제가 동시에 있으면\n카드결제로만 진행됩니다.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: DevCoopColors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildPaymentInfoRow(
                      '총 결제금액',
                      widget.totalAmount,
                      DevCoopTextStyle.light_40,
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentInfoRow(
                      '아리페이 결제',
                      widget.paymentAmount,
                      DevCoopTextStyle.medium_30,
                    ),
                    if (widget.cardAmount > 0) ...[
                      const SizedBox(height: 8),
                      _buildPaymentInfoRow(
                        '카드 결제',
                        widget.cardAmount,
                        DevCoopTextStyle.medium_30,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const LinearProgressIndicator(
                backgroundColor: DevCoopColors.grey,
                valueColor:
                    AlwaysStoppedAnimation<Color>(DevCoopColors.primary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isCancelPressed
                    ? null
                    : () {
                        setState(() => _isCancelPressed = true);
                        widget.onClose();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DevCoopColors.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isCancelPressed ? '취소 처리 중...' : '결제 취소',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfoRow(String label, int amount, TextStyle style) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          '${NumberFormatUtil.convert1000Number(amount)}원',
          style: style,
        ),
      ],
    );
  }
}
