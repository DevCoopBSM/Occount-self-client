import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'provider/auth_provider.dart';
import 'provider/payment_provider.dart';
import 'provider/navigation_provider.dart';
import 'provider/item_provider.dart';
import 'api/api_config.dart';
import 'services/payment_service.dart';
import 'services/payment_calculation_service.dart';
import 'services/auth_service.dart';
import 'api/api_client.dart';
import 'services/item_service.dart';
import 'services/event_service.dart';
import 'ui/home/home.dart';
import 'ui/login/barcode_scan_page.dart';
import 'ui/login/pin_page.dart';
import 'services/category_service.dart';
import 'provider/category_provider.dart';
import 'services/charge_service.dart';
import 'ui/payments/payment_page.dart';

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(
    (record) {
      debugPrint('${record.time}: ${record.level.name}: ${record.message}');
    },
  );

  final apiConfig = ApiConfig();
  final client = http.Client();
  final apiClient = ApiClient(client: client, apiConfig: apiConfig);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => apiClient,
        ),
        Provider<ItemService>(
          create: (context) => ItemService(context.read<ApiClient>()),
        ),
        Provider<EventService>(
          create: (context) => EventService(apiClient),
        ),
        Provider<CategoryService>(
          create: (context) => CategoryService(apiClient: apiClient),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(apiClient),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            Provider.of<AuthService>(context, listen: false),
          ),
        ),
        Provider<PaymentService>(
          create: (context) => PaymentService(apiClient),
        ),
        Provider<ChargeService>(
          create: (context) => ChargeService(),
        ),
        Provider<PaymentCalculationService>(
          create: (context) => PaymentCalculationService(),
        ),
        ChangeNotifierProvider(
          create: (context) => NavigationProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => CategoryProvider(
            Provider.of<CategoryService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ItemProvider(
            Provider.of<ItemService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PaymentProvider(
            Provider.of<PaymentService>(context, listen: false),
            Provider.of<ItemService>(context, listen: false),
            Provider.of<ChargeService>(context, listen: false),
          ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: globalNavigatorKey,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        initialRoute: '/',
        routes: {
          '/': (context) => Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.isLoading) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return authProvider.isLoggedIn
                      ? const Home()
                      : const BarcodeScanPage();
                },
              ),
          '/payment': (context) => const PaymentPage(),
          '/pin': (context) => const PinPage(),
        },
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final navigationProvider =
        Provider.of<NavigationProvider>(context, listen: false);

    return MaterialApp(
      navigatorKey: navigationProvider.navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return authProvider.isLoggedIn
                    ? const Home()
                    : const BarcodeScanPage();
              },
            ),
        '/payment': (context) => const PaymentPage(),
        '/pin': (context) => const PinPage(),
      },
      scaffoldMessengerKey: rootScaffoldMessengerKey,
    );
  }
}
