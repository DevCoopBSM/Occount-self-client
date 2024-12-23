import 'package:flutter/material.dart';
import '../../_constant/util/number_format_util.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';

class PaymentProcessingDialog extends StatelessWidget {
  final int totalAmount;
  final int paymentAmount;
  final int cardAmount;
  final bool isChargeOnly;

  const PaymentProcessingDialog({
    Key? key,
    required this.totalAmount,
    required this.paymentAmount,
    required this.cardAmount,
    required this.isChargeOnly,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                cardAmount > 0
                    ? Icons.credit_card
                    : Icons.account_balance_wallet,
                size: 48,
                color: DevCoopColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                cardAmount > 0 ? '카드 결제가 진행중입니다' : '포인트 결제가 진행중입니다',
                style: DevCoopTextStyle.bold_40.copyWith(
                  fontSize: 24,
                  color: DevCoopColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!isChargeOnly) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DevCoopColors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildPaymentInfoRow(
                        '아리페이 결제',
                        paymentAmount,
                        DevCoopTextStyle.medium_30,
                      ),
                      if (cardAmount > 0) ...[
                        const SizedBox(height: 8),
                        _buildPaymentInfoRow(
                          '카드 결제',
                          cardAmount,
                          DevCoopTextStyle.medium_30,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const LinearProgressIndicator(
                backgroundColor: DevCoopColors.grey,
                valueColor:
                    AlwaysStoppedAnimation<Color>(DevCoopColors.primary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('결제 취소'),
                      content: const Text('결제를 취소하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('아니오'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop(false);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('예'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red,
                  minimumSize: const Size(120, 40),
                ),
                child: const Text('결제 취소'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
