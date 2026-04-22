import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occount_self/ui/components/session_expired_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'SessionExpiredDialog shows kiosk-styled content and confirm action',
      (tester) async {
    var confirmPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionExpiredDialog(
            onConfirm: () {
              confirmPressed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('세션 만료'), findsOneWidget);
    expect(find.text('결제 제한시간이 지났습니다.\n다시 로그인 해주세요.'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
    expect(find.byIcon(Icons.access_time_filled_rounded), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(confirmPressed, isTrue);
  });
}
