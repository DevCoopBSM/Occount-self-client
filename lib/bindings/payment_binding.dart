import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controller/payment_controller.dart';
import '../service/payment_service.dart';
import '../service/payment_calculation_service.dart';
import '../secure/db.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    final dbSecure = DbSecure();
    final client = http.Client();

    Get.put(PaymentService(
      dbSecure: dbSecure,
      client: client,
    ));
    Get.put(PaymentCalculationService());
    Get.put(PaymentController(
      Get.find<PaymentService>(),
      Get.find<PaymentCalculationService>(),
    ));
  }
}
