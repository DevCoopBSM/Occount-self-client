import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/payment_provider.dart';
import '../../_constant/util/number_format_util.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';
import '../../../provider/auth_provider.dart';

class PaymentSummary extends StatelessWidget {
  final int currentPoints;

  const PaymentSummary({
    Key? key,
    required this.currentPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final paymentProvider = Provider.of<PaymentProvider>(context);
        final effectivePoints = authProvider.isGuestMode ? 0 : currentPoints;
        final calculation = paymentProvider.calculatePayment(
          authProvider.cartItems,
          effectivePoints,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DevCoopColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DevCoopColors.grey),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('총 결제금액', style: DevCoopTextStyle.medium_30),
                  Text(
                    '${NumberFormatUtil.convert1000Number(calculation.totalPrice)}원',
                    style: DevCoopTextStyle.bold_30,
                  ),
                ],
              ),
              if (!calculation.isChargeOnly) ...[
                const Divider(color: DevCoopColors.grey),
                if (!authProvider.isGuestMode) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('포인트 사용', style: DevCoopTextStyle.medium_30),
                      Text(
                        '${NumberFormatUtil.convert1000Number(calculation.expectedPoints)}원',
                        style: DevCoopTextStyle.medium_30,
                      ),
                    ],
                  ),
                ],
                if (calculation.expectedCardAmount > 0 || authProvider.isGuestMode) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        authProvider.isGuestMode ? '카드 결제' : '카드 결제',
                        style: DevCoopTextStyle.medium_30,
                      ),
                      Text(
                        '${NumberFormatUtil.convert1000Number(authProvider.isGuestMode ? calculation.totalPrice : calculation.expectedCardAmount)}원',
                        style: DevCoopTextStyle.medium_30,
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
