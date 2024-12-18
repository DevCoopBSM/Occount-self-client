import 'package:get/get.dart';
import '../controller/payment_controller.dart';
import '../service/payment_service.dart';
import 'package:http/http.dart' as http;
import '../secure/db.dart';

class PaymentBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<PaymentController>(
      PaymentController(
        PaymentService(
          dbSecure: Get.find<DbSecure>(),
          client: http.Client(),
        ),
      ),
    );
  }
}
