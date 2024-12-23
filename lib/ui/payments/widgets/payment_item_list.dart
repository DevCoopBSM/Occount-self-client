import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'payment_item_card.dart';
import '../../../provider/auth_provider.dart';

class PaymentItemList extends StatelessWidget {
  const PaymentItemList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.cartItems.isEmpty) {
          return const Center(
            child: Text(
              '상품을 추가해주세요',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: authProvider.cartItems.length,
          itemBuilder: (context, index) {
            final item = authProvider.cartItems[index];
            return PaymentItemCard(item: item);
          },
        );
      },
    );
  }
}
