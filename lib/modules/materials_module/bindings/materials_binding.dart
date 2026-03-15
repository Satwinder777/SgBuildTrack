import 'package:get/get.dart';
import '../controllers/materials_controller.dart';
import '../controllers/material_form_controller.dart';

class MaterialsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MaterialsController>(() => MaterialsController());
    Get.lazyPut<MaterialFormController>(() => MaterialFormController());
  }
}
