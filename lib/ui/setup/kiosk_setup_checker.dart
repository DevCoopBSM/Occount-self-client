import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/kiosk_config_service.dart';
import '../login/barcode_scan_page.dart';
import '../settings/kiosk_config_page.dart';

class KioskSetupChecker extends StatefulWidget {
  const KioskSetupChecker({Key? key}) : super(key: key);

  @override
  State<KioskSetupChecker> createState() => _KioskSetupCheckerState();
}

class _KioskSetupCheckerState extends State<KioskSetupChecker> {
  bool _isLoading = true;
  bool _hasKioskId = false;

  @override
  void initState() {
    super.initState();
    _checkKioskSetup();
  }

  Future<void> _checkKioskSetup() async {
    try {
      final kioskConfigService = context.read<KioskConfigService>();
      final hasId = await kioskConfigService.hasKioskId();

      if (mounted) {
        setState(() {
          _hasKioskId = hasId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasKioskId = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasKioskId) {
      // 키오스크 ID가 설정되어 있으면 일반 로그인 화면
      return const BarcodeScanPage();
    } else {
      // 키오스크 ID가 없으면 설정 화면
      return const KioskConfigPage();
    }
  }
}