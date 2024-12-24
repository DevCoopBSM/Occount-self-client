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
import 'services/person_counter_service.dart';

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

  debugPrint('🚀 Initializing providers...');

  final serviceProviders = [
    Provider<ApiClient>(create: (_) => apiClient),
    Provider<AuthService>(create: (_) => AuthService(apiClient)),
    Provider<ItemService>(create: (_) => ItemService(apiClient)),
    Provider<PaymentService>(create: (_) => PaymentService(apiClient)),
    Provider<CategoryService>(
        create: (_) => CategoryService(apiClient: apiClient)),
    Provider<EventService>(create: (_) => EventService(apiClient)),
    Provider<ChargeService>(create: (_) => ChargeService()),
    Provider<PaymentCalculationService>(
        create: (_) => PaymentCalculationService()),
    Provider<PersonCounterService>.value(
      value: PersonCounterService(),
    ),
  ];

  debugPrint('✅ All providers initialized');

  final stateProviders = [
    ChangeNotifierProvider<AuthProvider>(
      create: (context) => AuthProvider(context.read<AuthService>()),
    ),
    ChangeNotifierProvider<NavigationProvider>(
      create: (_) => NavigationProvider(),
    ),
    ChangeNotifierProvider<CategoryProvider>(
      create: (context) => CategoryProvider(context.read<CategoryService>()),
    ),
    ChangeNotifierProvider<ItemProvider>(
      create: (context) => ItemProvider(context.read<ItemService>()),
    ),
    ChangeNotifierProvider<PaymentProvider>(
      create: (context) => PaymentProvider(
        context.read<PaymentService>(),
        context.read<ItemService>(),
        context.read<ChargeService>(),
      ),
    ),
  ];

  runApp(
    MultiProvider(
      providers: [
        ...serviceProviders,
        ...stateProviders,
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
