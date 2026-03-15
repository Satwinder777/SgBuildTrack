import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/usecases/predict_future_cost_usecase.dart';

class AiPredictionController extends GetxController {
  AiPredictionController({PredictFutureCostUseCase? useCase})
      : _predictUseCase = useCase ?? PredictFutureCostUseCase();

  final PredictFutureCostUseCase _predictUseCase;
  final formKey = GlobalKey<FormState>();

  final previousCost = 0.0.obs;
  final growthRatePercent = 10.0.obs;
  final predictedAmount = 0.0.obs;

  void setPreviousCost(double v) => previousCost.value = v;
  void setGrowthRate(double v) => growthRatePercent.value = v;

  void calculate() {
    final result = _predictUseCase(
      previousCost.value,
      growthRatePercent.value,
    );
    predictedAmount.value = result;
    AppLogger.calc('AI prediction calculated', data: {
      'previousCost': previousCost.value,
      'growthRate': growthRatePercent.value,
      'predicted': result,
    });
  }
}
