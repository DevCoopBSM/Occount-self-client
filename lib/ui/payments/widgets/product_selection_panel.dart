import 'package:flutter/material.dart';
import 'barcode_input.dart';
import 'payment_item_header.dart';

class ProductSelectionPanel extends StatelessWidget {
  const ProductSelectionPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerRight,
          child: const BarcodeInput(),
        ),
        const SizedBox(height: 20),
        const Divider(color: Colors.black, thickness: 4),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const PaymentItemHeader(),
          ),
        ),
      ],
    );
  }
}
