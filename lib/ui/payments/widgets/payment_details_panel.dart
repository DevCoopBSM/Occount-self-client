import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/payment_controller.dart';
import 'payment_item_header.dart';
import 'payment_item_list.dart';
import 'payment_total.dart';

class PaymentDetailsPanel extends GetView<PaymentController> {
  const PaymentDetailsPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Divider(color: Colors.black, thickness: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: const Column(
                children: [
                  PaymentItemHeader(),
                  SizedBox(height: 30),
                  Expanded(child: PaymentItemList()),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.black, thickness: 4),
          const PaymentTotal(),
        ],
      ),
    );
  }
}
