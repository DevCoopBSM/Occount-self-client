import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/payment_controller.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';

class ProductList extends GetView<PaymentController> {
  const ProductList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.selectedProductType.value == "바코드 없는 상품"
        ? _buildNonBarcodeItems()
        : const Center(
            child: Text(
              "행사상품이 없습니다",
              style: DevCoopTextStyle.bold_30,
            ),
          ));
  }

  Widget _buildNonBarcodeItems() {
    return ListView.builder(
      itemCount: controller.nonBarcodeItems.length,
      itemBuilder: (context, index) {
        final item = controller.nonBarcodeItems[index];
        return GestureDetector(
          onTap: () => controller.addNonBarcodeItem(item),
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: index % 2 == 0
                  ? DevCoopColors.primaryLight
                  : DevCoopColors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.itemName,
                  style: DevCoopTextStyle.bold_20,
                ),
                Text(
                  '${item.itemPrice}원',
                  style: DevCoopTextStyle.bold_20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
