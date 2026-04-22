import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/payment_provider.dart';
import '../../../provider/auth_provider.dart';
import '../../_constant/component/button.dart';

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
            if (!authProvider.isGuestMode)
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
                onTap: () async {
                  await authProvider.returnToLanding();
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context, rootNavigator: true)
                      .pushNamedAndRemoveUntil(
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
                  Icon(Icons.payment, weight: 20),
                  Text("결제",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                ],
              ),
              onTap: () async {
                if (authProvider.userInfo.userCode.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('사용자 정보가 없습니다.')),
                  );
                  return;
                }

                // 명세서 변경: userCode/userName 제거 — 토큰 기반 인증
                await paymentProvider.processPayment(
                  context: context,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
