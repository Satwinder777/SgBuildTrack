import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/validators/form_validators.dart';
import '../../../data/models/labour_model.dart';
import '../controllers/labour_form_controller.dart';

class LabourFormView extends GetView<LabourFormController> {
  const LabourFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isEdit ? AppStrings.editLabour : AppStrings.addLabour,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    initialValue: controller.name.value,
                    decoration: const InputDecoration(labelText: AppStrings.name),
                    validator: FormValidators.required,
                    onChanged: controller.setName,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: controller.phone.value,
                    decoration: const InputDecoration(labelText: AppStrings.phone),
                    keyboardType: TextInputType.phone,
                    validator: FormValidators.phone,
                    onChanged: controller.setPhone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: controller.address.value,
                    decoration: const InputDecoration(labelText: AppStrings.address),
                    maxLines: 2,
                    onChanged: controller.setAddress,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<LabourType>(
                    value: controller.labourType.value,
                    decoration: const InputDecoration(labelText: AppStrings.labourType),
                    items: LabourType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.displayName),
                            ))
                        .toList(),
                    onChanged: (t) => t != null ? controller.setLabourType(t) : null,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<LabourPaymentMode>(
                    segments: const [
                      ButtonSegment(
                        value: LabourPaymentMode.hourly,
                        label: Text(AppStrings.hourly),
                        icon: Icon(Icons.schedule),
                      ),
                      ButtonSegment(
                        value: LabourPaymentMode.fixed,
                        label: Text(AppStrings.fixed),
                        icon: Icon(Icons.calendar_today),
                      ),
                    ],
                    selected: {controller.paymentMode.value},
                    onSelectionChanged: (s) {
                      if (s.isNotEmpty) controller.setPaymentMode(s.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (controller.paymentMode.value == LabourPaymentMode.hourly) ...[
                    TextFormField(
                      initialValue: controller.workHours.value > 0
                          ? controller.workHours.value.toString()
                          : '',
                      decoration: const InputDecoration(
                        labelText: AppStrings.workHours,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: FormValidators.workHoursOrRate,
                      onChanged: (v) =>
                          controller.setWorkHours(double.tryParse(v) ?? 0),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: controller.hourlyRate.value > 0
                          ? controller.hourlyRate.value.toString()
                          : '',
                      decoration: const InputDecoration(
                        labelText: AppStrings.hourlyRate,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: FormValidators.workHoursOrRate,
                      onChanged: (v) =>
                          controller.setHourlyRate(double.tryParse(v) ?? 0),
                    ),
                  ] else
                    TextFormField(
                      initialValue: controller.fixedDayRate.value > 0
                          ? controller.fixedDayRate.value.toString()
                          : '',
                      decoration: const InputDecoration(
                        labelText: AppStrings.fixedDayRate,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: FormValidators.workHoursOrRate,
                      onChanged: (v) =>
                          controller.setFixedDayRate(double.tryParse(v) ?? 0),
                    ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final date = controller.date.value;
                    return InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: date ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) controller.setDate(d);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: AppStrings.date,
                          errorText: date == null ? AppStrings.validationSelectDate : null,
                          errorStyle: const TextStyle(height: 0.01),
                        ),
                        child: Text(
                          date != null
                              ? date.toString().substring(0, 10)
                              : 'Tap to select',
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text('Total: ₹${controller.totalPayment.value.toStringAsFixed(2)}',
                      style: Get.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: controller.notes.value,
                    decoration: const InputDecoration(labelText: AppStrings.notes),
                    maxLines: 2,
                    onChanged: controller.setNotes,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () {
                            if (!(controller.formKey.currentState?.validate() ?? false)) return;
                            if (controller.date.value == null) {
                              Get.snackbar('Error', AppStrings.validationSelectDate);
                              return;
                            }
                            controller.save();
                          },
                    child: controller.isSaving.value
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.save),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
