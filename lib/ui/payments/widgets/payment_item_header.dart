import 'package:flutter/material.dart';
import '../../_constant/theme/devcoop_text_style.dart';

class PaymentItemHeader extends StatelessWidget {
  const PaymentItemHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text('상품 이름', style: DevCoopTextStyle.medium_30),
        ),
        Container(
          width: 100,
          alignment: Alignment.center,
          child: const Text('이벤트', style: DevCoopTextStyle.medium_30),
        ),
        Container(
          width: 155,
          alignment: Alignment.centerRight,
          child: const Text('수량', style: DevCoopTextStyle.medium_30),
        ),
        Container(
          width: 155,
          alignment: Alignment.centerRight,
          child: const Text('상품 가격', style: DevCoopTextStyle.medium_30),
        ),
        const SizedBox(width: 118), // 버튼 공간
      ],
    );
  }
}
