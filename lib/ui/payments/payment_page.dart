import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import 'widgets/payment_header.dart';
import 'widgets/payment_item_list.dart';
import 'widgets/payment_item_header.dart';
import 'widgets/payment_action_buttons.dart';
import 'widgets/payment_summary.dart';
import 'widgets/barcode_input.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final barcodeInputKey = GlobalKey<BarcodeInputState>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        return; // void 반환
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                PaymentHeader(
                  userInfo: authProvider.userInfo,
                ),
                const SizedBox(height: 20),
                BarcodeInput(key: barcodeInputKey),
                const SizedBox(height: 10),
                const PaymentItemHeader(),
                const SizedBox(height: 10),
                const Expanded(
                  child: PaymentItemList(),
                ),
                const SizedBox(height: 20),
                if (authProvider.cartItems.isNotEmpty) ...[
                  PaymentSummary(
                    currentPoints: authProvider.userInfo.userPoint,
                  ),
                  const SizedBox(height: 20),
                ],
                const PaymentActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
