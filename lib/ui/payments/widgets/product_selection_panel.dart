import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/payment_controller.dart';
import 'product_type_selector.dart';
import 'product_list.dart';
import 'barcode_input.dart';

class ProductSelectionPanel extends GetView<PaymentController> {
  const ProductSelectionPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Column(
        children: [
          ProductTypeSelector(),
          SizedBox(height: 20),
          BarcodeInput(),
          SizedBox(height: 20),
          Divider(color: Colors.black, thickness: 4),
          Expanded(child: ProductList()),
        ],
      ),
    );
  }
}
