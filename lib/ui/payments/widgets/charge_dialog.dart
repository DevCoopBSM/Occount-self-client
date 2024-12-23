import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:counter/ui/_constant/component/button.dart';
import '../../../provider/payment_provider.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/util/number_format_util.dart';
import '../../_constant/theme/devcoop_text_style.dart';

class ChargeDialog extends StatelessWidget {
  const ChargeDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);

    return AlertDialog(
      title: Text(
        '아리페이 충전',
        style: DevCoopTextStyle.bold_40.copyWith(
          fontSize: 24,
          color: DevCoopColors.black,
        ),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '충전 금액: ${NumberFormatUtil.convert1000Number(paymentProvider.chargeAmount)}원',
              style: DevCoopTextStyle.bold_40.copyWith(
                fontSize: 30,
                color: DevCoopColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildAmountButtons(paymentProvider),
            const SizedBox(height: 20),
            _buildActionButtons(context, paymentProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountButtons(PaymentProvider provider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAmountButton('+1000', () => provider.addChargeAmount(1000)),
            _buildAmountButton('+100', () => provider.addChargeAmount(100)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAmountButton('+10', () => provider.addChargeAmount(10)),
            _buildAmountButton('+1', () => provider.addChargeAmount(1)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, PaymentProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAmountButton('초기화', () => provider.resetChargeAmount(),
            color: DevCoopColors.error),
        _buildAmountButton('완료', () {
          provider.confirmCharge(context);
          Navigator.of(context).pop();
        }, color: DevCoopColors.primary),
      ],
    );
  }

  Widget _buildAmountButton(String text, VoidCallback onPressed,
      {Color? color}) {
    return mainTextButton(
      text: text,
      onTap: onPressed,
      color: color,
    );
  }
}
