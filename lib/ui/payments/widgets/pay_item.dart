import 'package:flutter/material.dart';
import 'package:counter/models/cart_item.dart';
import 'package:counter/ui/_constant/theme/devcoop_colors.dart';
import 'package:counter/ui/_constant/theme/devcoop_text_style.dart';
import 'package:counter/ui/_constant/component/button.dart';
import 'package:counter/ui/_constant/util/number_format_util.dart';

Widget paymentsItem({
  required String itemName,
  required String type,
  required dynamic center,
  required String plus,
  required String minus,
  required int right,
  String? rightText,
  bool totalText = true,
  required void Function(void Function()) setState,
  required List<CartItem> items,
  required void Function(int) onTotalPriceChanged,
}) {
  return Row(
    children: [
      Expanded(
        child: Text(
          itemName,
          style: totalText
              ? DevCoopTextStyle.bold_30.copyWith(color: DevCoopColors.black)
              : DevCoopTextStyle.light_30.copyWith(color: DevCoopColors.black),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Container(
        width: 100,
        alignment: Alignment.center,
        child: Text(
          type,
          style: totalText
              ? DevCoopTextStyle.medium_30.copyWith(color: DevCoopColors.black)
              : DevCoopTextStyle.medium_30.copyWith(color: DevCoopColors.error),
        ),
      ),
      Container(
        width: 155,
        alignment: Alignment.centerRight,
        child: Text(
          center.toString(),
          style: totalText
              ? DevCoopTextStyle.bold_30.copyWith(color: DevCoopColors.black)
              : DevCoopTextStyle.light_30.copyWith(color: DevCoopColors.black),
        ),
      ),
      Container(
        width: 155,
        alignment: Alignment.centerRight,
        child: Text(
          rightText ?? NumberFormatUtil.convert1000Number(right),
          style: totalText
              ? DevCoopTextStyle.bold_30.copyWith(color: DevCoopColors.black)
              : DevCoopTextStyle.light_30.copyWith(color: DevCoopColors.black),
        ),
      ),
      const SizedBox(width: 10),
      Container(
        alignment: Alignment.center,
        child: mainTextButton(
          text: plus,
          onTap: () {
            setState(() {
              final item = items.firstWhere(
                (item) => item.itemName == itemName,
                orElse: () => CartItem(
                  itemId: 0,
                  itemCode: '',
                  itemName: itemName,
                  itemPrice: 0,
                  itemCategory: '',
                ),
              );
              item.quantity += 1;
              final newTotalPrice = items.fold<int>(
                0,
                (sum, item) => sum + (item.totalPrice),
              );
              onTotalPriceChanged(newTotalPrice);
            });
          },
        ),
      ),
      const SizedBox(width: 10),
      Container(
        alignment: Alignment.center,
        child: mainTextButton(
          text: minus,
          onTap: () {
            setState(() {
              final index =
                  items.indexWhere((item) => item.itemName == itemName);
              if (index != -1) {
                if (items[index].quantity > 1) {
                  items[index].quantity -= 1;
                } else {
                  items.removeAt(index);
                }
              }

              final newTotalPrice = items.fold<int>(
                0,
                (sum, item) => sum + (item.totalPrice),
              );
              onTotalPriceChanged(newTotalPrice);
            });
          },
        ),
      ),
    ],
  );
}
