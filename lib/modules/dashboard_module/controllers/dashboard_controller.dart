import 'dart:async';
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
import '../../../domain/entities/dashboard_summary_entity.dart';

/// Filter for dashboard period (charts / optional period stats).
enum DashboardFilter { today, thisWeek, thisMonth }

class DashboardController extends GetxController {
  DashboardController({
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
  StreamSubscription? _attendanceAllSub;
  StreamSubscription? _materialsSub;
  StreamSubscription? _workerPaymentsSub;

  // ——— Reactive data from streams ———
  final workers = <LabourModel>[].obs;
  final attendanceToday = <AttendanceModel>[].obs;
  final attendanceAll = <AttendanceModel>[].obs;
  final materials = <MaterialModel>[].obs;
  final workerPayments = <WorkerPaymentRecordModel>[].obs;

  // ——— Reactive stats (recomputed when data changes) ———
  final totalWorkers = 0.obs;
  final presentToday = 0.obs;
  final absentToday = 0.obs;
  final totalHoursToday = 0.0.obs;
  final todayLabourCost = 0.0.obs;
  final totalMaterialCost = 0.0.obs;
  final totalPaymentsMade = 0.0.obs;
  final pendingPayments = 0.0.obs;
  final categoryCostMap = <String, double>{}.obs;

  /// Labour cost per day for the current filter range (for Labour Cost Chart).
  final labourCostByDay = <DateTime, double>{}.obs;
  /// Present/absent per day for the current filter range (for Attendance Chart).
  final attendanceByDay = <DateTime, ({int present, int absent})>{}.obs;

  final isLoading = true.obs;
  final loadError = Rxn<String>();
  final filter = DashboardFilter.today.obs;

  /// Legacy summary for backward compatibility (derived from reactive stats).
  DashboardSummaryEntity get summaryEntity => DashboardSummaryEntity(
        totalMaterialCost: totalMaterialCost.value,
        totalLabourCost: totalLabourEarnings,
        totalPaidAmount: totalPaymentsMade.value,
        totalPendingAmount: pendingPayments.value,
        totalConstructionCost: totalMaterialCost.value + totalLabourEarnings,
      );

  double get totalLabourEarnings =>
      DashboardCalculationService.calculateTotalLabourEarnings(
        attendance: attendanceAll,
        workers: workers,
      );

  @override
  void onReady() {
    _bindStreams();
    super.onReady();
  }

  @override
  void onClose() {
    _labourSub?.cancel();
    _attendanceTodaySub?.cancel();
    _attendanceAllSub?.cancel();
    _materialsSub?.cancel();
    _workerPaymentsSub?.cancel();
    super.onClose();
  }

  void _bindStreams() {
    loadError.value = null;
    isLoading.value = true;

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final twoYearsAgo = today.subtract(const Duration(days: 730));

    _labourSub?.cancel();
    _labourSub = _labourRepo
        .streamLabour(limit: AppConstants.defaultPageSize * 3)
        .listen(_onWorkers, onError: _onError('workers'));

    _attendanceTodaySub?.cancel();
    _attendanceTodaySub = _attendanceRepo
        .streamAttendanceForDate(today)
        .listen(_onAttendanceToday, onError: _onError('attendanceToday'));

    _attendanceAllSub?.cancel();
    _attendanceAllSub = _attendanceRepo
        .streamAttendance(fromDate: twoYearsAgo, toDate: today.add(const Duration(days: 1)), limit: 2000)
        .listen(_onAttendanceAll, onError: _onError('attendanceAll'));

    _materialsSub?.cancel();
    _materialsSub = _materialRepo
        .streamMaterials(limit: 500)
        .listen(_onMaterials, onError: _onError('materials'));

    _workerPaymentsSub?.cancel();
    _workerPaymentsSub = _workerPaymentRepo
        .streamWorkerPayments(limit: 1000)
        .listen(_onWorkerPayments, onError: _onError('workerPayments'));
  }

  void _onWorkers(List<LabourModel> list) {
    workers.assignAll(list);
    _updateStats();
  }

  void _onAttendanceToday(List<AttendanceModel> list) {
    attendanceToday.assignAll(list);
    _updateStats();
  }

  void _onAttendanceAll(List<AttendanceModel> list) {
    attendanceAll.assignAll(list);
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
        AppLogger.error('Dashboard stream error: $source', error: e);
        loadError.value = 'Failed to load $source';
        _updateStats();
      };

  void _updateStats() {
    try {
      totalWorkers.value = DashboardCalculationService.calculateTotalWorkers(workers);
      presentToday.value = DashboardCalculationService.calculatePresentToday(attendanceToday);
      absentToday.value = DashboardCalculationService.calculateAbsentToday(attendanceToday);
      totalHoursToday.value = DashboardCalculationService.calculateTotalHoursToday(attendanceToday);
      todayLabourCost.value = DashboardCalculationService.calculateTodayLabourCost(
        attendanceToday: attendanceToday,
        workers: workers,
      );
      totalMaterialCost.value = DashboardCalculationService.calculateTotalMaterialCost(materials);
      totalPaymentsMade.value = DashboardCalculationService.calculateTotalPaymentsMade(workerPayments);
      final earnings = DashboardCalculationService.calculateTotalLabourEarnings(
        attendance: attendanceAll,
        workers: workers,
      );
      pendingPayments.value = DashboardCalculationService.calculatePendingPayments(
        totalLabourEarnings: earnings,
        totalPaymentsMade: totalPaymentsMade.value,
      );
      categoryCostMap.assignAll(
        DashboardCalculationService.calculateMaterialCostByCategory(materials),
      );
      final (rangeStart, rangeEnd) = filterDateRange;
      labourCostByDay.value = Map.from(
        DashboardCalculationService.calculateLabourCostByDay(
          attendance: attendanceAll,
          workers: workers,
          startDate: rangeStart,
          endDate: rangeEnd,
        ),
      );
      attendanceByDay.value = Map.from(
        DashboardCalculationService.calculateAttendanceByDay(
          attendance: attendanceAll,
          startDate: rangeStart,
          endDate: rangeEnd,
        ),
      );
      isLoading.value = false;
      AppLogger.calc('Dashboard updated');
      AppLogger.calc('Workers: ${totalWorkers.value}');
      AppLogger.calc('Present Today: ${presentToday.value}');
      AppLogger.calc('Labour Cost Today: ${todayLabourCost.value}');
      debugPrint('Dashboard updated');
      debugPrint('Workers: ${totalWorkers.value}');
      debugPrint('Present Today: ${presentToday.value}');
      debugPrint('Labour Cost Today: ${todayLabourCost.value}');
    } catch (e, st) {
      AppLogger.error('Dashboard stats calculation failed', error: e, stackTrace: st);
      loadError.value = 'Calculation error';
    }
  }

  void setFilter(DashboardFilter value) {
    filter.value = value;
    _updateStats();
  }

  /// Re-bind streams (e.g. after error or pull-to-refresh).
  void refreshStreams() {
    _bindStreams();
  }

  /// Date range for current filter (for charts).
  (DateTime start, DateTime end) get filterDateRange {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    switch (filter.value) {
      case DashboardFilter.today:
        return (end, end);
      case DashboardFilter.thisWeek:
        return (end.subtract(const Duration(days: 6)), end);
      case DashboardFilter.thisMonth:
        return (end.subtract(const Duration(days: 29)), end);
    }
  }
}
