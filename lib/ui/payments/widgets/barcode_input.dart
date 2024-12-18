import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/payment_controller.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/component/button.dart';

class BarcodeInput extends GetView<PaymentController> {
  const BarcodeInput({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 20),
            height: 60.0,
            width: 300.0,
            child: TextFormField(
              controller: controller.barcodeController,
              focusNode: controller.barcodeFocusNode,
              onFieldSubmitted: (_) => controller.handleBarcodeSubmit(),
              decoration: const InputDecoration(
                hintText: '상품 바코드를 입력해주세요',
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: DevCoopColors.transparent),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: DevCoopColors.grey),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: DevCoopColors.transparent),
                ),
              ),
            ),
          ),
        ),
        mainTextButton(
          text: const Icon(Icons.check, weight: 10.0),
          onTap: () => controller.handleBarcodeSubmit(),
        ),
      ],
    );
  }
}
