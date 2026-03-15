import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/dashboard_calculation_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/labour_model.dart';
import '../../../data/models/material_model.dart';
import '../../../data/models/worker_payment_record_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/attendance_repository_interface.dart';
import '../../../data/repositories/labour_repository.dart';
import '../../../data/repositories/labour_repository_interface.dart';
import '../../../data/repositories/material_repository.dart';
import '../../../data/repositories/material_repository_interface.dart';
import '../../../data/repositories/worker_payment_repository.dart';
import '../../../data/repositories/worker_payment_repository_interface.dart';

enum ReportsFilter { today, thisWeek, thisMonth, custom }

class ReportsController extends GetxController {
  ReportsController({
    LabourRepositoryInterface? labourRepo,
    AttendanceRepositoryInterface? attendanceRepo,
    MaterialRepositoryInterface? materialRepo,
    WorkerPaymentRepositoryInterface? workerPaymentRepo,
  })  : _labourRepo = labourRepo ?? LabourRepository(),
        _attendanceRepo = attendanceRepo ?? AttendanceRepository(),
        _materialRepo = materialRepo ?? MaterialRepository(),
        _workerPaymentRepo = workerPaymentRepo ?? WorkerPaymentRepository();

  final LabourRepositoryInterface _labourRepo;
  final AttendanceRepositoryInterface _attendanceRepo;
  final MaterialRepositoryInterface _materialRepo;
  final WorkerPaymentRepositoryInterface _workerPaymentRepo;

  StreamSubscription? _labourSub;
  StreamSubscription? _attendanceTodaySub;
  StreamSubscription? _attendancePeriodSub;
  StreamSubscription? _materialsSub;
  StreamSubscription? _workerPaymentsSub;

  final workers = <LabourModel>[].obs;
  final attendanceToday = <AttendanceModel>[].obs;
  final attendancePeriod = <AttendanceModel>[].obs;
  final materials = <MaterialModel>[].obs;
  final workerPayments = <WorkerPaymentRecordModel>[].obs;

  final totalWorkers = 0.obs;
  final presentToday = 0.obs;
  final absentToday = 0.obs;
  final totalLabourCost = 0.0.obs;
  final totalMaterialCost = 0.0.obs;
  final totalPaymentsMade = 0.0.obs;
  final pendingPayments = 0.0.obs;

  final labourCostByDay = <DateTime, double>{}.obs;
  final attendanceByDay = <DateTime, ({int present, int absent})>{}.obs;
  final paymentByDay = <DateTime, double>{}.obs;
  final categoryCostMap = <String, double>{}.obs;

  final filter = ReportsFilter.thisMonth.obs;
  DateTime? customStartDate;
  DateTime? customEndDate;
  final searchQuery = ''.obs;

  final isLoading = true.obs;
  final loadError = Rxn<String>();

  (DateTime start, DateTime end) get filterDateRange {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    switch (filter.value) {
      case ReportsFilter.today:
        return (end, end);
      case ReportsFilter.thisWeek:
        return (end.subtract(const Duration(days: 6)), end);
      case ReportsFilter.thisMonth:
        return (end.subtract(const Duration(days: 29)), end);
      case ReportsFilter.custom:
        final s = customStartDate ?? end.subtract(const Duration(days: 29));
        final e = customEndDate ?? end;
        return (s.isBefore(e) ? s : e, e.isAfter(s) ? e : s);
    }
  }

  List<LabourModel> get filteredWorkers {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return workers;
    return workers.where((w) => w.name.toLowerCase().contains(q)).toList();
  }

  List<MaterialModel> get filteredMaterials {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return materials;
    final amount = num.tryParse(q);
    return materials.where((m) {
      if (m.materialName.toLowerCase().contains(q)) return true;
      if (amount != null && (m.totalPrice - amount).abs() < 0.01) return true;
      return false;
    }).toList();
  }

  List<WorkerPaymentRecordModel> get filteredWorkerPayments {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return workerPayments;
    final amount = num.tryParse(q);
    return workerPayments.where((p) {
      if (amount != null && (p.amountPaid - amount).abs() < 0.01) return true;
      final w = workers.where((x) => x.id == p.workerId).firstOrNull;
      if (w != null && w.name.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  double get totalLabourEarnings =>
      DashboardCalculationService.calculateTotalLabourEarnings(
        attendance: attendancePeriod,
        workers: workers,
      );

  int get periodPresent =>
      attendancePeriod.where((a) => a.isPresent).length;
  int get periodAbsent =>
      attendancePeriod.where((a) => a.isAbsent).length;
  double get attendancePercentageValue {
    final total = periodPresent + periodAbsent;
    if (total == 0) return 0;
    return (periodPresent / total) * 100;
  }

  @override
  void onReady() {
    _bindStreams();
    super.onReady();
  }

  @override
  void onClose() {
    _labourSub?.cancel();
    _attendanceTodaySub?.cancel();
    _attendancePeriodSub?.cancel();
    _materialsSub?.cancel();
    _workerPaymentsSub?.cancel();
    super.onClose();
  }

  void setFilter(ReportsFilter value) {
    filter.value = value;
    _updatePeriodStream();
    _updateStats();
    AppLogger.calc('Reports filter changed');
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    customStartDate = DateTime(start.year, start.month, start.day);
    customEndDate = DateTime(end.year, end.month, end.day);
    filter.value = ReportsFilter.custom;
    _updatePeriodStream();
    _updateStats();
  }

  void setSearch(String query) {
    searchQuery.value = query;
  }

  void refreshStreams() {
    _bindStreams();
  }

  void _bindStreams() {
    loadError.value = null;
    isLoading.value = true;

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    _labourSub?.cancel();
    _labourSub = _labourRepo
        .streamLabour(limit: AppConstants.defaultPageSize * 3)
        .listen(_onWorkers, onError: _onError('workers'));

    _attendanceTodaySub?.cancel();
    _attendanceTodaySub = _attendanceRepo
        .streamAttendanceForDate(today)
        .listen(_onAttendanceToday, onError: _onError('attendanceToday'));

    _attendancePeriodSub?.cancel();
    _updatePeriodStream();

    _materialsSub?.cancel();
    _materialsSub = _materialRepo
        .streamMaterials(limit: 500)
        .listen(_onMaterials, onError: _onError('materials'));

    _workerPaymentsSub?.cancel();
    _workerPaymentsSub = _workerPaymentRepo
        .streamWorkerPayments(limit: 1000)
        .listen(_onWorkerPayments, onError: _onError('workerPayments'));
  }

  void _updatePeriodStream() {
    final (start, end) = filterDateRange;
    _attendancePeriodSub?.cancel();
    _attendancePeriodSub = _attendanceRepo
        .streamAttendance(
          fromDate: start,
          toDate: end.add(const Duration(days: 1)),
          limit: 2000,
        )
        .listen(_onAttendancePeriod, onError: _onError('attendancePeriod'));
  }

  void _onWorkers(List<LabourModel> list) {
    workers.assignAll(list);
    _updateStats();
  }

  void _onAttendanceToday(List<AttendanceModel> list) {
    attendanceToday.assignAll(list);
    _updateStats();
  }

  void _onAttendancePeriod(List<AttendanceModel> list) {
    attendancePeriod.assignAll(list);
    _updateStats();
  }

  void _onMaterials(List<MaterialModel> list) {
    materials.assignAll(list);
    _updateStats();
  }

  void _onWorkerPayments(List<WorkerPaymentRecordModel> list) {
    workerPayments.assignAll(list);
    _updateStats();
  }

  void Function(dynamic) _onError(String source) => (e) {
        AppLogger.error('Reports stream error: $source', error: e);
        loadError.value = 'Failed to load $source';
        _updateStats();
      };

  void _updateStats() {
    try {
      totalWorkers.value = DashboardCalculationService.calculateTotalWorkers(workers);
      presentToday.value = DashboardCalculationService.calculatePresentToday(attendanceToday);
      absentToday.value = DashboardCalculationService.calculateAbsentToday(attendanceToday);

      totalLabourCost.value = totalLabourEarnings;

      totalMaterialCost.value = DashboardCalculationService.calculateTotalMaterialCost(materials);
      totalPaymentsMade.value = DashboardCalculationService.calculateTotalPaymentsMade(workerPayments);
      pendingPayments.value = DashboardCalculationService.calculatePendingPayments(
        totalLabourEarnings: totalLabourEarnings,
        totalPaymentsMade: totalPaymentsMade.value,
      );

      final (rangeStart, rangeEnd) = filterDateRange;
      labourCostByDay.value = Map.from(
        DashboardCalculationService.calculateLabourCostByDay(
          attendance: attendancePeriod,
          workers: workers,
          startDate: rangeStart,
          endDate: rangeEnd,
        ),
      );
      attendanceByDay.value = Map.from(
        DashboardCalculationService.calculateAttendanceByDay(
          attendance: attendancePeriod,
          startDate: rangeStart,
          endDate: rangeEnd,
        ),
      );
      final payByDay = <DateTime, double>{};
      for (final p in workerPayments) {
        final d = DateTime(p.paymentDate.year, p.paymentDate.month, p.paymentDate.day);
        if (!d.isBefore(rangeStart) && !d.isAfter(rangeEnd)) {
          payByDay[d] = (payByDay[d] ?? 0) + p.amountPaid;
        }
      }
      paymentByDay.value = payByDay;
      categoryCostMap.assignAll(
        DashboardCalculationService.calculateMaterialCostByCategory(materials),
      );

      isLoading.value = false;
      debugPrint('Reports loaded');
      AppLogger.calc('Attendance report calculated');
      AppLogger.calc('Material cost report updated');
    } catch (e, st) {
      AppLogger.error('Reports stats calculation failed', error: e, stackTrace: st);
      loadError.value = 'Calculation error';
    }
  }
}
