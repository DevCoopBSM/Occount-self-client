import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/payment_controller.dart';
import '../../_constant/component/button.dart';

class PaymentActionButtons extends GetView<PaymentController> {
  const PaymentActionButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          mainTextButton(
            text: const Row(children: [
              Icon(Icons.delete, weight: 20),
              Text("삭제",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
            ]),
            onTap: () => controller.clearItems(),
          ),
          const SizedBox(width: 20),
          mainTextButton(
            text: const Row(children: [
              Icon(Icons.logout, weight: 20),
              Text("홈으로",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
            ]),
            onTap: () => controller.logout(),
          ),
          const SizedBox(width: 20),
          mainTextButton(
            text: const Row(children: [
              Icon(Icons.account_balance_wallet, weight: 20),
              Text("셀프 충전",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
            ]),
            onTap: () => controller.showChargeDialog(),
          ),
          const SizedBox(width: 20),
          Obx(() => mainTextButton(
                text: const Row(children: [
                  Icon(Icons.payment, weight: 20),
                  Text("결제",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                ]),
                onTap: controller.isProcessing.value
                    ? null
                    : controller.processPayment,
              )),
        ],
      ),
    );
  }
}
