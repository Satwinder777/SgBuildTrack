import 'package:get/get.dart';
import '../controllers/worker_payment_controller.dart';

class WorkerPaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WorkerPaymentController>(() => WorkerPaymentController());
  }
}
