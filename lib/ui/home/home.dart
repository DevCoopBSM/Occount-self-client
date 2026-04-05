import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/navigation_provider.dart';
import '../payments/payment_page.dart';
import '../login/barcode_scan_page.dart';
import '../login/pin_page.dart';
import 'package:logging/logging.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final _logger = Logger('HomeState');

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 Home widget initState called');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _logger.info('📱 App lifecycle state changed to: $state');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, _) {
        return PopScope(
          canPop: false,
          child: Scaffold(
            body: Navigator(
              initialRoute: '/scan',
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/scan':
                    return MaterialPageRoute(
                      builder: (_) => const BarcodeScanPage(),
                    );
                  case '/payment':
                    return MaterialPageRoute(
                      builder: (_) => const PaymentPage(),
                    );
                  case '/pin':
                    return MaterialPageRoute(
                      builder: (_) => const PinPage(),
                      settings: settings,
                    );
                  default:
                    return MaterialPageRoute(
                      builder: (_) => const BarcodeScanPage(),
                    );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
