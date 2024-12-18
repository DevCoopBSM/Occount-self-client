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
      final bool isPaymentPossible =
          controller.currentUser.point >= controller.totalPrice.value;

      if (!isPaymentPossible) {
        return const Text(
          "잔액이 부족합니다",
          style: TextStyle(
            color: DevCoopColors.error,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        );
      }

      return Row(
        children: [
          const Expanded(
            child: Text(
              '총 가격',
              style: DevCoopTextStyle.bold_30,
            ),
          ),
          Container(
            width: 100,
            alignment: Alignment.center,
            child: const Text(''),
          ),
          Container(
            width: 155,
            alignment: Alignment.centerRight,
            child: Text(
              controller.itemResponses
                  .fold<int>(0, (sum, item) => sum + (item.quantity))
                  .toString(),
              style: DevCoopTextStyle.bold_30,
            ),
          ),
          Container(
            width: 155,
            alignment: Alignment.centerRight,
            child: Text(
              NumberFormatUtil.convert1000Number(controller.totalPrice.value),
              style: DevCoopTextStyle.bold_30,
            ),
          ),
          const SizedBox(width: 118),
        ],
      );
    });
  }
}
