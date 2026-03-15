import 'dart:async';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/date_filter.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/labour_model.dart';
import '../../../data/repositories/labour_repository.dart';

class LabourController extends GetxController {
  LabourController({LabourRepository? repository})
      : _repo = repository ?? LabourRepository();

  final LabourRepository _repo;
  StreamSubscription? _labourSub;

  final labourList = <LabourModel>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final dateFilterType = DateFilterType.all.obs;

  @override
  void onReady() {
    subscribeLabour();
    super.onReady();
  }

  @override
  void onClose() {
    _labourSub?.cancel();
    super.onClose();
  }

  void subscribeLabour() {
    _labourSub?.cancel();
    isLoading.value = true;
    final range = dateFilterType.value.range;
    _labourSub = _repo.streamLabour(
      limit: AppConstants.defaultPageSize,
      fromDate: range != null ? range[0] : null,
      toDate: range != null ? range[1] : null,
      searchQuery: searchQuery.value.isEmpty ? null : searchQuery.value,
    ).listen((list) {
      labourList.assignAll(list);
      isLoading.value = false;
    }, onError: (e) {
      AppLogger.error('Labour stream error', error: e);
      isLoading.value = false;
    });
  }

  void setSearch(String query) {
    searchQuery.value = query;
    subscribeLabour();
  }

  void setDateFilter(DateFilterType type) {
    dateFilterType.value = type;
    subscribeLabour();
  }

  void clearFilters() {
    searchQuery.value = '';
    dateFilterType.value = DateFilterType.all;
    subscribeLabour();
  }

  Future<void> deleteLabour(String id) async {
    await _repo.deleteLabour(id);
  }
}
