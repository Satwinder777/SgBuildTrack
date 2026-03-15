import 'package:get/get.dart';
import '../../modules/dashboard_module/controllers/dashboard_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}
