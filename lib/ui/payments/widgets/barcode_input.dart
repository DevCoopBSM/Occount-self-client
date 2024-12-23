import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../_constant/theme/devcoop_text_style.dart';
import '../../_constant/component/button.dart';
import '../../../provider/payment_provider.dart';
import './non_barcode_dialog.dart';

class BarcodeInput extends StatefulWidget {
  const BarcodeInput({Key? key}) : super(key: key);

  @override
  State<BarcodeInput> createState() => BarcodeInputState();
}

class BarcodeInputState extends State<BarcodeInput> {
  final FocusNode barcodeFocus = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(barcodeFocus);
      }
    });
  }

  @override
  void dispose() {
    barcodeFocus.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeSubmit(String value) async {
    if (!mounted) return;

    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    try {
      await paymentProvider.addItemByBarcode(value, context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      _barcodeController.clear();
      FocusScope.of(context).requestFocus(barcodeFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = DevCoopTextStyle.medium_20.copyWith(
      color: Colors.black,
    );

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECECEC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextFormField(
              controller: _barcodeController,
              focusNode: barcodeFocus,
              onFieldSubmitted: (value) {
                if (value.isNotEmpty) {
                  _handleBarcodeSubmit(value);
                }
              },
              decoration: InputDecoration(
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintText: '바코드를 스캔해주세요',
                hintStyle: DevCoopTextStyle.medium_30.copyWith(fontSize: 15),
                border: InputBorder.none,
              ),
              maxLines: 1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: mainTextButton(
            text: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_shopping_cart, size: 20),
                const SizedBox(width: 4),
                Text(
                  "바코드 없는 상품",
                  style: textStyle,
                ),
              ],
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const NonBarcodeDialog(),
              );
            },
          ),
        ),
      ],
    );
  }
}
