import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/payment_controller.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';
import '../../_constant/util/number_format_util.dart';

class PaymentTotal extends GetView<PaymentController> {
  const PaymentTotal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int currentPoints = controller.currentUser.point;
      final int totalAmount = controller.totalPrice.value;
      final int expectedCardAmount =
          totalAmount > currentPoints ? totalAmount - currentPoints : 0;

      if (expectedCardAmount > 0) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "사용 가능 포인트: ${NumberFormatUtil.convert1000Number(currentPoints)}원",
              style: const TextStyle(
                fontSize: 24,
                color: DevCoopColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "카드 결제 예정: ${NumberFormatUtil.convert1000Number(expectedCardAmount)}원",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: DevCoopColors.primary,
              ),
            ),
          ],
        );
      }

      return Text(
        "포인트로 결제 가능",
        style: const TextStyle(
          color: DevCoopColors.primary,
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
      );
    });
  }
}
