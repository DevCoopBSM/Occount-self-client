import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:occount_self/ui/payments/widgets/payment_result_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'PaymentResultDialog closes back to cart when shouldReturnToHome is false',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const PaymentResultDialog(
                      errorMessage: '결제 시간이 초과되었습니다.',
                      errorCode: 'PAYMENT_TIMEOUT',
                      isSuccess: false,
                      shouldReturnToHome: false,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentResultDialog), findsOneWidget);
    expect(find.text('장바구니로'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentResultDialog), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
