import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/cart_item.dart';
import '../../../provider/auth_provider.dart';
import '../../_constant/util/number_format_util.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';

class PaymentItemCard extends StatelessWidget {
  final CartItem item;

  const PaymentItemCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                item.itemName,
                style: DevCoopTextStyle.medium_30,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                item.itemCategory == 'EVENT' ? '이벤트' : '',
                style: DevCoopTextStyle.medium_30,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (item.quantity <= 1) {
                        authProvider.removeFromCart(item);
                      } else {
                        authProvider.decreaseQuantity(item.itemId);
                      }
                    },
                  ),
                  Text(
                    '${item.quantity}',
                    style: DevCoopTextStyle.medium_30,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => authProvider.increaseQuantity(item.itemId),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${NumberFormatUtil.convert1000Number(item.itemPrice)}원',
                style: DevCoopTextStyle.medium_30,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
