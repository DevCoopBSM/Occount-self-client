import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/payment_provider.dart';
import '../../../provider/auth_provider.dart';
import '../../_constant/component/button.dart';
import 'charge_dialog.dart';

class PaymentActionButtons extends StatelessWidget {
  const PaymentActionButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            mainTextButton(
              text: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_forever, weight: 20),
                  Text("전체 삭제",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                ],
              ),
              onTap: () => authProvider.clearCart(),
            ),
            const SizedBox(width: 20),
            mainTextButton(
              text: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, weight: 20),
                  Text("홈으로",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                ],
              ),
              onTap: () {
                authProvider.logout();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              },
            ),
            const SizedBox(width: 20),
            mainTextButton(
              text: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet, weight: 20),
                  Text("셀프 충전",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                ],
              ),
              onTap: () => _showChargeDialog(context),
            ),
            const SizedBox(width: 20),
            mainTextButton(
              text: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payment, weight: 20),
                  Text("결제",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                ],
              ),
              onTap: () async {
                if (paymentProvider.isProcessing) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('결제 처리 중입니다...')),
                  );
                  return;
                }

                if (authProvider.userInfo.userCode.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('사용자 정보가 없습니다.')),
                  );
                  return;
                }

                try {
                  await paymentProvider.processPayment(
                    context: context,
                    userCode: authProvider.userInfo.userCode,
                    userName: authProvider.userInfo.userName,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('결제 처리 중 오류가 발생했습니다: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showChargeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ChargeDialog(),
    );
  }
}
