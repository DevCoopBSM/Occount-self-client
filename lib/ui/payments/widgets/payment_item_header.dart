import 'package:flutter/material.dart';
import '../../_constant/theme/devcoop_text_style.dart';

class PaymentItemHeader extends StatelessWidget {
  const PaymentItemHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          flex: 4,
          child: Text('상품 이름', style: DevCoopTextStyle.medium_30),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '이벤트',
            style: DevCoopTextStyle.medium_30,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '수량',
            style: DevCoopTextStyle.medium_30,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '상품 가격',
            style: DevCoopTextStyle.medium_30,
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(width: 20),
      ],
    );
  }
}
