import 'package:flutter/material.dart';
import '../../../controller/payment_controller.dart';
import 'package:get/get.dart';
import 'payment_item_tile.dart';

class PaymentItemList extends GetView<PaymentController> {
  const PaymentItemList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: controller.itemResponses.length,
              itemBuilder: (context, index) {
                final item = controller.itemResponses[index];
                return PaymentItemTile(item: item);
              },
            ),
          ),
        ],
      ),
    );
  }
}
