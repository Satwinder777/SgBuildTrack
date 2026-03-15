import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/material_calculator.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/material_model.dart';
import '../../../data/repositories/material_repository.dart';

class MaterialFormController extends GetxController {
  MaterialFormController({MaterialRepository? repository})
      : _repo = repository ?? MaterialRepository();

  final MaterialRepository _repo;
  final _uuid = const Uuid();
  final formKey = GlobalKey<FormState>();

  final id = ''.obs;
  final category = MaterialCategory.other.obs;
  final materialName = ''.obs;
  final quantity = 0.0.obs;
  final unitType = MaterialUnit.piece.obs;
  final pricePerUnit = 0.0.obs;
  final totalPrice = 0.0.obs;
  final supplierName = ''.obs;
  final purchaseDate = Rxn<DateTime>();
  final notes = ''.obs;
  final isSaving = false.obs;
  DateTime? _initialCreatedAt;

  bool get isEdit => id.value.isNotEmpty;

  @override
  void onInit() {
    final arg = Get.arguments as MaterialModel?;
    if (arg != null) {
      id.value = arg.id;
      category.value = arg.category;
      materialName.value = arg.materialName;
      quantity.value = arg.quantity;
      unitType.value = arg.category.isUnitLocked ? arg.category.defaultUnit : arg.unitType;
      pricePerUnit.value = arg.pricePerUnit;
      totalPrice.value = arg.totalPrice;
      supplierName.value = arg.supplierName ?? '';
      purchaseDate.value = arg.purchaseDate ?? DateTime.now();
      notes.value = arg.notes ?? '';
      _initialCreatedAt = arg.createdAt;
    } else {
      // id.value = _uuid.v4();
      purchaseDate.value = DateTime.now();
    }
    recalculateTotal();
    super.onInit();
  }

  void setCategory(MaterialCategory c) {
    category.value = c;
    // Lock unit to category's default/allowed unit
    unitType.value = c.defaultUnit;
    recalculateTotal();
  }

  void setMaterialName(String v) => materialName.value = v;

  void setQuantity(double v) {
    quantity.value = v < 0 ? 0 : v;
    recalculateTotal();
  }

  /// Only allowed when category is "other" (unit not locked).
  void setUnitType(MaterialUnit u) {
    if (!category.value.isUnitLocked) {
      unitType.value = u;
      recalculateTotal();
    }
  }

  void setPricePerUnit(double v) {
    pricePerUnit.value = v < 0 ? 0 : v;
    recalculateTotal();
  }
  void setSupplierName(String v) => supplierName.value = v;
  void setPurchaseDate(DateTime? d) => purchaseDate.value = d;
  void setNotes(String v) => notes.value = v;

  /// Live calculation: totalCost = quantity × pricePerUnit (GetX reactive).
  void recalculateTotal() {
    totalPrice.value = MaterialCalculator.calculateWithLogs(
      materialName: materialName.value.isEmpty ? 'Material' : materialName.value,
      quantity: quantity.value,
      pricePerUnit: pricePerUnit.value,
      unitLabel: unitType.value.displayName,
    );
  }

  /// True when unit is fixed by category (user cannot change).
  bool get isUnitLocked => category.value.isUnitLocked;

  Future<bool> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return false;
    if (materialName.value.trim().isEmpty) {
      Get.snackbar('Error', 'Material name is required');
      return false;
    }
    if (quantity.value <= 0) {
      Get.snackbar('Error', 'Quantity must be greater than 0');
      return false;
    }
    if (pricePerUnit.value <= 0) {
      Get.snackbar('Error', 'Price per unit must be greater than 0');
      return false;
    }
    try {
      category.value.validateUnit(unitType.value);
    } on MaterialUnitException catch (e) {
      Get.snackbar('Invalid unit', e.message);
      return false;
    }
    recalculateTotal();
    isSaving.value = true;
    try {
      final now = DateTime.now();
      final total = MaterialCalculator.calculateMaterialCost(
        quantity: quantity.value,
        pricePerUnit: pricePerUnit.value,
      );
      final model = MaterialModel(
        id: _uuid.v4(),
        category: category.value,
        materialName: materialName.value.trim(),
        quantity: quantity.value,
        unitType: unitType.value,
        pricePerUnit: pricePerUnit.value,
        totalPrice: total,
        supplierName: supplierName.value.trim().isEmpty ? null : supplierName.value.trim(),
        purchaseDate: purchaseDate.value ?? now,
        notes: notes.value.trim().isEmpty ? null : notes.value.trim(),
        createdAt: isEdit ? (_initialCreatedAt ?? now) : now,
        updatedAt: now,
      );
      if (isEdit) {
        await _repo.updateMaterial(model);
        AppLogger.form('Material updated', data: {'id': id.value});
      } else {
        await _repo.addMaterial(model);
        AppLogger.form('Material added', data: {'id': id.value});
      }
      Get.back(result: true);
      return true;
    } catch (e, st) {
      AppLogger.error('Material save failed', error: e, stackTrace: st);
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
