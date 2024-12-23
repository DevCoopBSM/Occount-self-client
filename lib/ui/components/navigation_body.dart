import 'package:flutter/material.dart';
import 'package:occount_self/ui/login/barcode_scan_page.dart';
import 'package:occount_self/ui/payments/payment_page.dart';

class NavigationBody extends StatelessWidget {
  final int index;

  const NavigationBody({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return const BarcodeScanPage();
      case 1:
        return const PaymentPage();
      default:
        return const BarcodeScanPage();
    }
  }
}
