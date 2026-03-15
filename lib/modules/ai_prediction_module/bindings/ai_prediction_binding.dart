import 'package:get/get.dart';
import '../controllers/ai_prediction_controller.dart';

class AiPredictionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiPredictionController>(() => AiPredictionController());
  }
}
