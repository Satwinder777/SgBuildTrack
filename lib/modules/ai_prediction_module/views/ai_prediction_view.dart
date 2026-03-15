import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/helper_functions/format_helpers.dart';
import '../../../core/validators/form_validators.dart';
import '../controllers/ai_prediction_controller.dart';

class AiPredictionView extends GetView<AiPredictionController> {
  const AiPredictionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.aiPrediction)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predict future construction cost based on previous expense and growth rate.',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Structure ready for OpenAI API integration.',
                      style: Get.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: AppStrings.previousCost,
                      hintText: 'e.g. 120000',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => FormValidators.priceOrAmount(v),
                    onChanged: (v) =>
                        controller.setPreviousCost(double.tryParse(v) ?? 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.growthRate} ${controller.growthRatePercent.value.toStringAsFixed(0)}%',
                      style: Get.textTheme.titleSmall,
                    ),
                    Slider(
                      value: controller.growthRatePercent.value,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      label: '${controller.growthRatePercent.value.toStringAsFixed(0)}%',
                      onChanged: controller.setGrowthRate,
                    ),
                  ],
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (controller.formKey.currentState?.validate() ?? false) {
                  controller.calculate();
                }
              },
              child: const Text(AppStrings.predictCost),
            ),
            const SizedBox(height: 32),
            Obx(() {
              if (controller.predictedAmount.value <= 0) {
                return const SizedBox.shrink();
              }
              return Card(
                color: AppColors.primary.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.predictedAmount,
                        style: Get.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        FormatHelpers.formatCurrency(
                            controller.predictedAmount.value),
                        style: Get.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
