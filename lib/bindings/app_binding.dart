import 'package:get/get.dart';
import '../secure/db.dart';
import '../service/payment_service.dart';
import 'package:http/http.dart' as http;
import '../controller/user_controller.dart';
import '../controller/bottom_navigation_controller.dart';

class AppBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(DbSecure());
    Get.put(
      PaymentService(
        dbSecure: Get.find<DbSecure>(),
        client: http.Client(),
      ),
      permanent: true,
    );
    Get.put(
      UserController(),
      permanent: true,
    );
    Get.put(BottomNavigationController());
  }
}
