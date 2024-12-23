import 'package:flutter/material.dart';
import '../../../models/cart_item.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import '../../../ui/_constant/util/number_format_util.dart';

class PaymentItemTile extends StatelessWidget {
  final CartItem item;

  const PaymentItemTile({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return ListTile(
      title: Text(item.itemName),
      subtitle: Text(NumberFormatUtil.convert1000Number(item.itemPrice)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => authProvider.decreaseQuantity(item.itemId),
          ),
          Text('${item.quantity}'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => authProvider.increaseQuantity(item.itemId),
          ),
        ],
      ),
    );
  }
}
