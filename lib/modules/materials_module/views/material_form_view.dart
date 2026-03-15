import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/helper_functions/format_helpers.dart';
import '../../../core/validators/form_validators.dart';
import '../../../data/models/material_model.dart';
import '../controllers/material_form_controller.dart';

class MaterialFormView extends GetView<MaterialFormController> {
  const MaterialFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isEdit ? AppStrings.editMaterial : AppStrings.addMaterial,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.category, style: Get.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<MaterialCategory>(
                          value: controller.category.value,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            errorStyle: TextStyle(height: 0.01),
                          ),
                          items: MaterialCategory.values
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.displayName),
                                  ))
                              .toList(),
                          onChanged: (c) => c != null ? controller.setCategory(c) : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: controller.materialName.value,
                          decoration: const InputDecoration(
                            labelText: AppStrings.materialName,
                            border: OutlineInputBorder(),
                            hintText: 'e.g. Cement, Bricks',
                          ),
                          validator: FormValidators.required,
                          onChanged: controller.setMaterialName,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: controller.quantity.value > 0
                                    ? controller.quantity.value.toString()
                                    : '',
                                decoration: const InputDecoration(
                                  labelText: AppStrings.quantity,
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: FormValidators.quantity,
                                onChanged: (v) =>
                                    controller.setQuantity(double.tryParse(v) ?? 0),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: controller.isUnitLocked
                                  ? InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: AppStrings.unit,
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      child: Text(
                                        controller.unitType.value.displayName,
                                        style: Get.textTheme.bodyLarge,
                                      ),
                                    )
                                  : DropdownButtonFormField<MaterialUnit>(
                                      value: controller.unitType.value,
                                      decoration: const InputDecoration(
                                        labelText: AppStrings.unit,
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        errorStyle: TextStyle(height: 0.01),
                                      ),
                                      isExpanded: true,
                                      items: controller.category.value.allowedUnits
                                          .map((u) => DropdownMenuItem(
                                                value: u,
                                                child: Text(
                                                  u.displayName,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ))
                                          .toList(),
                                      selectedItemBuilder: (context) => controller.category.value.allowedUnits
                                          .map((u) => Text(
                                                u.displayName,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.bodyLarge,
                                              ))
                                          .toList(),
                                      onChanged: (u) => u != null ? controller.setUnitType(u) : null,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: controller.pricePerUnit.value > 0
                              ? controller.pricePerUnit.value.toString()
                              : '',
                          decoration: const InputDecoration(
                            labelText: AppStrings.pricePerUnit,
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => FormValidators.priceOrAmount(v, allowZero: false),
                          onChanged: (v) =>
                              controller.setPricePerUnit(double.tryParse(v) ?? 0),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Get.theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: Get.textTheme.titleSmall),
                              Text(
                                FormatHelpers.formatCurrency(controller.totalPrice.value),
                                style: Get.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          initialValue: controller.supplierName.value,
                          decoration: const InputDecoration(
                            labelText: AppStrings.supplierName,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: controller.setSupplierName,
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
                          final date = controller.purchaseDate.value;
                          return InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: date ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) controller.setPurchaseDate(d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: AppStrings.purchaseDate,
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                date != null
                                    ? '${date.day}/${date.month}/${date.year}'
                                    : 'Tap to select date',
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: controller.notes.value,
                          decoration: const InputDecoration(
                            labelText: AppStrings.notes,
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 2,
                          onChanged: controller.setNotes,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(() => FilledButton(
                        onPressed: controller.isSaving.value
                            ? null
                            : () {
                                if (!(controller.formKey.currentState?.validate() ?? false)) return;
                                controller.save();
                              },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.isSaving.value
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                controller.isEdit ? 'Update Material' : 'Add Material',
                                style: const TextStyle(fontSize: 16),
                              ),
                      )),
                ],
              )),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Get.theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}
