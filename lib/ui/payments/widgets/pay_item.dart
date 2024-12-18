import 'package:counter/dto/item_response_dto.dart';
import 'package:counter/ui/_constant/theme/devcoop_colors.dart';
import 'package:counter/ui/_constant/theme/devcoop_text_style.dart';
import 'package:counter/ui/_constant/util/number_format_util.dart';
import 'package:flutter/material.dart';

Widget paymentsItem({
  required String itemName,
  required String type,
  required dynamic center,
  required String plus,
  required String minus,
  int? right,
  String? rightText,
  bool totalText = true,
  required void Function(void Function()) setState,
  required List<ItemResponseDto> itemResponses,
  required int totalPrice,
}) {
  return Row(
    children: [
      Expanded(
        child: Text(
          itemName,
          style: totalText
              ? DevCoopTextStyle.bold_30.copyWith(
                  color: DevCoopColors.black,
                )
              : DevCoopTextStyle.light_30.copyWith(
                  color: DevCoopColors.black,
                ),
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
              ? DevCoopTextStyle.medium_30.copyWith(
                  color: DevCoopColors.black,
                )
              : DevCoopTextStyle.medium_30.copyWith(
                  color: DevCoopColors.error,
                ),
        ),
      ),
      Container(
        width: 155,
        alignment: Alignment.centerRight,
        child: Text(
          "$center",
          style: totalText
              ? DevCoopTextStyle.bold_30.copyWith(
                  color: DevCoopColors.black,
                )
              : DevCoopTextStyle.light_30.copyWith(
                  color: DevCoopColors.black,
                ),
        ),
      ),
      Container(
        width: 155,
        alignment: Alignment.centerRight,
        child: Text(rightText ?? NumberFormatUtil.convert1000Number(right ?? 0),
            style: totalText
                ? DevCoopTextStyle.bold_30.copyWith(
                    color: DevCoopColors.black,
                  )
                : DevCoopTextStyle.light_30.copyWith(
                    color: DevCoopColors.black,
                  )),
      ),
      const SizedBox(width: 10),
      plus.isNotEmpty
          ? Container(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    // 상품 수량 추가
                    itemResponses
                        .firstWhere((element) => element.itemName == itemName)
                        .quantity += 1;

                    // 수량 증가 시 총 가격 업데이트
                    totalPrice = itemResponses.fold(
                      0,
                      (sum, item) => sum + item.itemPrice * item.quantity,
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DevCoopColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: const BorderSide(
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  plus,
                  textAlign: TextAlign.center,
                  style: DevCoopTextStyle.bold_30.copyWith(
                    color: DevCoopColors.black,
                    fontSize: 30,
                  ),
                ),
              ),
            )
          : const SizedBox(width: 54),
      const SizedBox(width: 10),
      plus.isNotEmpty
          ? Container(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    for (int i = 0; i < itemResponses.length; i++) {
                      if (itemResponses[i].itemName == itemName) {
                        if (itemResponses[i].quantity > 1) {
                          itemResponses[i].quantity -= 1;
                        } else {
                          itemResponses.removeAt(i);
                        }
                        break;
                      }
                    }

                    // 수량 감소 또는 상품 삭제 후 총 가격 업데이트
                    totalPrice = itemResponses.fold(
                      0,
                      (sum, item) => sum + item.itemPrice * item.quantity,
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DevCoopColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: const BorderSide(
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  minus,
                  textAlign: TextAlign.center,
                  style: DevCoopTextStyle.bold_30.copyWith(
                    color: DevCoopColors.black,
                    fontSize: 30,
                  ),
                ),
              ),
            )
          : const SizedBox(width: 54),
    ],
  );
}
