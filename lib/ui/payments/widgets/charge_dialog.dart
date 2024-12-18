import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/payment_controller.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/util/number_format_util.dart';

class ChargeDialog extends GetView<PaymentController> {
  const ChargeDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '아리페이 충전',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Text(
                  '충전 금액: ${NumberFormatUtil.convert1000Number(controller.chargeAmount.value)}원',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )),
            const SizedBox(height: 20),
            _buildAmountButtons(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAmountButton('+1000', () => controller.addChargeAmount(1000)),
            _buildAmountButton('+100', () => controller.addChargeAmount(100)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAmountButton('+10', () => controller.addChargeAmount(10)),
            _buildAmountButton('+1', () => controller.addChargeAmount(1)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAmountButton('초기화', () => controller.resetChargeAmount(),
            color: DevCoopColors.error),
        _buildAmountButton('완료', () => controller.confirmCharge(),
            color: DevCoopColors.primary),
      ],
    );
  }

  Widget _buildAmountButton(String text, VoidCallback onPressed,
      {Color? color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? DevCoopColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
