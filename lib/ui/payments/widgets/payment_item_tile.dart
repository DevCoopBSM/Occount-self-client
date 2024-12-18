import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/payment_controller.dart';
import '../../../dto/item_response_dto.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';
import '../../_constant/util/number_format_util.dart';

class PaymentItemTile extends StatelessWidget {
  final ItemResponseDto item;

  const PaymentItemTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaymentController>();
    final isChargeItem = item.type == 'CHARGE';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.itemName,
              style: DevCoopTextStyle.light_30,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 100,
            alignment: Alignment.center,
            child: Text(
              _getEventText(),
              style: DevCoopTextStyle.medium_30.copyWith(
                color: isChargeItem ? DevCoopColors.error : DevCoopColors.black,
              ),
            ),
          ),
          Container(
            width: 155,
            alignment: Alignment.centerRight,
            child: Text(
              item.quantity.toString(),
              style: DevCoopTextStyle.light_30,
            ),
          ),
          Container(
            width: 155,
            alignment: Alignment.centerRight,
            child: Text(
              NumberFormatUtil.convert1000Number(
                  item.itemPrice * item.quantity),
              style: DevCoopTextStyle.light_30,
            ),
          ),
          if (!isChargeItem) ...[
            const SizedBox(width: 10),
            _buildQuantityButton(
                '+', () => controller.increaseQuantity(item.itemId)),
            const SizedBox(width: 10),
            _buildQuantityButton(
                '-', () => controller.decreaseQuantity(item.itemId)),
          ] else
            const SizedBox(width: 118),
        ],
      ),
    );
  }

  String _getEventText() {
    switch (item.type) {
      case 'NONE':
        return '일 반';
      case 'CHARGE':
        return '충 전';
      case 'ONE_PLUS_ONE':
        return '1 + 1';
      default:
        return '';
    }
  }

  Widget _buildQuantityButton(String text, VoidCallback onPressed) {
    return Container(
      alignment: Alignment.center,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DevCoopColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: const BorderSide(width: 1),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: DevCoopTextStyle.bold_30.copyWith(
            color: DevCoopColors.black,
            fontSize: 30,
          ),
        ),
      ),
    );
  }
}
