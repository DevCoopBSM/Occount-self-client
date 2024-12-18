import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/payment_controller.dart';
import '../../_constant/theme/devcoop_text_style.dart';

class PaymentHeader extends GetView<PaymentController> {
  const PaymentHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Obx(() => Row(
            children: [
              Text(
                controller.currentUser.name.isEmpty
                    ? "환영합니다!"
                    : "${controller.currentUser.name}님",
                style: DevCoopTextStyle.bold_30,
              ),
              const Spacer(),
              Text(
                "${controller.currentUser.point}원",
                style: DevCoopTextStyle.bold_30,
              ),
            ],
          )),
    );
  }
}
