import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../../provider/payment_provider.dart';
import 'widgets/payment_header.dart';
import 'widgets/payment_item_list.dart';
import 'widgets/payment_item_header.dart';
import 'widgets/payment_action_buttons.dart';
import 'widgets/payment_summary.dart';
import 'widgets/barcode_input.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final GlobalKey<BarcodeInputState> _barcodeInputKey =
      GlobalKey<BarcodeInputState>();

  @override
  void initState() {
    super.initState();
    _restoreBarcodeFocus();
  }

  void _restoreBarcodeFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _barcodeInputKey.currentState?.restoreBarcodeFocus();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _barcodeInputKey.currentState?.restoreBarcodeFocus();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _barcodeInputKey.currentState?.restoreBarcodeFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isPaymentInProgress =
        context.select<PaymentProvider, bool>((p) => p.isPaymentInProgress);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        return; // void 반환
      },
      child: AbsorbPointer(
        // 결제 요청이 진행 중인 동안(서버 응답 대기 찰나의 시간 포함) 결제 화면의
        // 모든 사용자 입력을 차단한다. 결제 처리 다이얼로그는 별도 라우트의
        // barrier로 화면을 덮지만, 다이얼로그가 표시되기 직전의 비동기 간격 동안
        // 발생할 수 있는 의도치 않은 조작(바코드 입력, +/-, 전체 삭제 등)을 방지.
        absorbing: isPaymentInProgress,
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
                  BarcodeInput(key: _barcodeInputKey),
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
      ),
    );
  }
}
