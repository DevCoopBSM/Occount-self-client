import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:google_fonts/google_fonts.dart';

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
import 'ui/home/home.dart';
import 'ui/login/pin_page.dart';
import 'services/category_service.dart';
import 'provider/category_provider.dart';
import 'services/charge_service.dart';
import 'services/kiosk_config_service.dart';
import 'ui/payments/payment_page.dart';
import 'ui/setup/kiosk_setup_checker.dart';
import 'ui/settings/kiosk_config_page.dart';

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
      // App-level logging already controls verbosity, so avoid Flutter's
      // additional throttling layer hiding or delaying records in the console.
      debugPrintSynchronously(
        '${record.time}: ${record.level.name}: ${record.message}',
      );
    },
  );

  final apiConfig = ApiConfig();
  final client = http.Client();
  final kioskConfigService = KioskConfigService();
  final apiClient = ApiClient(
      client: client,
      apiConfig: apiConfig,
      kioskConfigService: kioskConfigService);

  final serviceProviders = [
    Provider<ApiClient>(create: (_) => apiClient),
    Provider<AuthService>(create: (_) => AuthService(apiClient)),
    Provider<ItemService>(create: (_) => ItemService(apiClient)),
    Provider<KioskConfigService>(create: (_) => kioskConfigService),
    Provider<PaymentService>(
        create: (context) =>
            PaymentService(apiClient, context.read<KioskConfigService>())),
    Provider<CategoryService>(
        create: (_) => CategoryService(apiClient: apiClient)),
    Provider<ChargeService>(create: (_) => ChargeService()),
    Provider<PaymentCalculationService>(
        create: (_) => PaymentCalculationService()),
  ];

  final stateProviders = [
    ChangeNotifierProvider<AuthProvider>(
      create: (context) => AuthProvider(
        context.read<AuthService>(),
        context.read<KioskConfigService>(),
      ),
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

        // 한글 인코딩 지원 설정
        debugShowCheckedModeBanner: false,

        // 한글 지원 폰트 테마 설정
        theme: ThemeData(
          fontFamily: GoogleFonts.notoSans().fontFamily,
          textTheme: GoogleFonts.notoSansTextTheme(),
        ),

        initialRoute: '/',
        routes: {
          '/': (context) => Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.isLoading) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (authProvider.isLoggedIn || authProvider.isGuestMode) {
                    return const Home();
                  } else {
                    return const KioskSetupChecker();
                  }
                },
              ),
          '/payment': (context) => const PaymentPage(),
          '/pin': (context) => const PinPage(),
          '/admin': (context) => const KioskConfigPage(),
        },
      ),
    ),
  );
}
