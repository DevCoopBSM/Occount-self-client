import 'dart:async';

import 'package:counter/ui/_constant/util/app_router.dart';
import 'package:counter/ui/barcode/barcode_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '부산소프트웨어마이스터고등학교 매점 셀프계산대.',
      debugShowCheckedModeBanner: false,
      getPages: appRouter,
      initialRoute: '/',
      home: const BarcodePage(),
      // home: MultiProvider(
      //   providers: [
      //     ChangeNotifierProvider(
      //       create: (BuildContext context) => CountProvider(),
      //     ),
      //     ChangeNotifierProvider(
      //       create: (BuildContext context) => BottomNavigationProvider(),
      //     ),
      //   ],
      //   // child: const OnboardPage(),
      //   // child: Home(),
      //   child: const BarcodePage(),
      // ),
    );
  }
}
