import 'package:get/get.dart';
import '../controllers/labour_controller.dart';
import '../controllers/labour_form_controller.dart';

class LabourBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LabourController>(() => LabourController());
    Get.lazyPut<LabourFormController>(() => LabourFormController());
  }
}
