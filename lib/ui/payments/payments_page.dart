import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/payment_controller.dart';
import 'widgets/payment_header.dart';
import 'widgets/product_selection_panel.dart';
import 'widgets/payment_details_panel.dart';
import 'widgets/payment_action_buttons.dart';

class PaymentsPage extends GetView<PaymentController> {
  const PaymentsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          PaymentHeader(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ProductSelectionPanel(),
                ),
                SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: PaymentDetailsPanel(),
                ),
              ],
            ),
          ),
          PaymentActionButtons(),
        ],
      ),
    );
  }
}
