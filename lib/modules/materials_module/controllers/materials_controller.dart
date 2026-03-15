import 'dart:async';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/date_filter.dart';
import '../../../core/services/material_calculator.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/material_model.dart';
import '../../../data/repositories/material_repository.dart';

class MaterialsController extends GetxController {
  MaterialsController({MaterialRepository? repository})
      : _repo = repository ?? MaterialRepository();

  final MaterialRepository _repo;
  StreamSubscription? _materialsSub;

  final materials = <MaterialModel>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final selectedCategory = Rxn<String>();
  final fromDate = Rxn<DateTime>();
  final toDate = Rxn<DateTime>();
  final dateFilterType = DateFilterType.all.obs;

  @override
  void onReady() {
    subscribeMaterials();
    super.onReady();
  }

  @override
  void onClose() {
    _materialsSub?.cancel();
    super.onClose();
  }

  void subscribeMaterials() {
    _materialsSub?.cancel();
    isLoading.value = true;
    final range = dateFilterType.value.range;
    _materialsSub = _repo.streamMaterials(
      limit: AppConstants.defaultPageSize,
      category: selectedCategory.value,
      fromDate: range != null ? range[0] : fromDate.value,
      toDate: range != null ? range[1] : toDate.value,
      searchQuery: searchQuery.value.isEmpty ? null : searchQuery.value,
    ).listen((list) {
      materials.assignAll(list);
      isLoading.value = false;
    }, onError: (e) {
      AppLogger.error('Materials stream error', error: e);
      isLoading.value = false;
    });
  }

  void setSearch(String query) {
    searchQuery.value = query;
    subscribeMaterials();
  }

  void setCategoryFilter(String? category) {
    selectedCategory.value = category;
    subscribeMaterials();
  }

  void setDateFilter(DateFilterType type) {
    dateFilterType.value = type;
    subscribeMaterials();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    fromDate.value = from;
    toDate.value = to;
    dateFilterType.value = DateFilterType.all;
    subscribeMaterials();
  }

  void clearFilters() {
    selectedCategory.value = null;
    fromDate.value = null;
    toDate.value = null;
    dateFilterType.value = DateFilterType.all;
    searchQuery.value = '';
    subscribeMaterials();
  }

  Future<void> deleteMaterial(String id) async {
    await _repo.deleteMaterial(id);
  }

  /// Total cost = quantity × pricePerUnit (strict rule). Used for display/validation.
  static double calculateTotal(double quantity, double pricePerUnit) {
    return MaterialCalculator.calculateMaterialCost(
      quantity: quantity,
      pricePerUnit: pricePerUnit,
    );
  }

  Future<String?> uploadBillImage(dynamic file) async {
    if (file == null) return null;
    if (file is String) return file;
    return _repo.uploadBillImage(file as dynamic);
  }
}
