import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/payment_controller.dart';
import '../../../dto/item_response_dto.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/util/number_format_util.dart';

class PaymentTotal extends StatelessWidget {
  final int totalPrice;
  final int currentPoints;
  final List<ItemResponseDto> items;

  const PaymentTotal({
    Key? key,
    required this.totalPrice,
    required this.currentPoints,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PaymentController>(builder: (controller) {
      final isChargeOnly = items.every((item) => item.type == 'CHARGE');
      final hasChargeItem = items.any((item) => item.type == 'CHARGE');

      // 충전만 있는 경우
      if (isChargeOnly) {
        return Text(
          "충전 예정 금액: ${NumberFormatUtil.convert1000Number(totalPrice)}원",
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: DevCoopColors.primary,
          ),
        );
      }

      // 충전과 상품이 함께 있는 경우 (혼합 결제)
      if (hasChargeItem) {
        return Text(
          "카드 결제 예정: ${NumberFormatUtil.convert1000Number(totalPrice)}원",
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: DevCoopColors.primary,
          ),
        );
      }

      // 일반 상품만 있는 경우 (기존 포인트 결제 로직)
      final expectedCardAmount =
          totalPrice > currentPoints ? totalPrice - currentPoints : 0;

      if (expectedCardAmount > 0) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "사용 가능 포인트: ${NumberFormatUtil.convert1000Number(currentPoints)}원",
              style: const TextStyle(
                fontSize: 24,
                color: DevCoopColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "카드 결제 예정: ${NumberFormatUtil.convert1000Number(expectedCardAmount)}원",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: DevCoopColors.primary,
              ),
            ),
          ],
        );
      }

      return const Text(
        "포인트로 결제 가능",
        style: TextStyle(
          color: DevCoopColors.primary,
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
      );
    });
  }
}
