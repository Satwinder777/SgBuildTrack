import 'dart:async';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/services/payment_calculator.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/labour_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/attendance_repository_interface.dart';
import '../../../data/repositories/labour_repository.dart';
import '../../../data/repositories/labour_repository_interface.dart';
import '../../../core/utils/app_logger.dart';

/// Period filter for Present/Absent lists.
enum AttendanceListFilter { daily, weekly, monthly }

class AttendanceController extends GetxController {
  AttendanceController({
    AttendanceRepositoryInterface? attendanceRepo,
    LabourRepositoryInterface? labourRepo,
  })  : _attendanceRepo = attendanceRepo ?? AttendanceRepository(),
        _labourRepo = labourRepo ?? LabourRepository();

  final AttendanceRepositoryInterface _attendanceRepo;
  final LabourRepositoryInterface _labourRepo;
  final _uuid = const Uuid();

  StreamSubscription? _labourSub;
  StreamSubscription? _attendanceSub;
  StreamSubscription? _attendancePeriodSub;

  final workers = <LabourModel>[].obs;
  final attendanceForDate = <AttendanceModel>[].obs;
  /// For Weekly/Monthly filter: attendance in range.
  final attendanceForPeriod = <AttendanceModel>[].obs;
  final selectedDate = DateTime.now().obs;
  final isLoading = true.obs;
  final listFilter = AttendanceListFilter.daily.obs;
  final saveError = Rxn<String>();

  /// Search in Pending workers (name, phone, labour type).
  final searchQuery = ''.obs;

  /// Dashboard stats for selected date (kept for compatibility).
  final totalWorkers = 0.obs;
  final presentCount = 0.obs;
  final absentCount = 0.obs;
  final leaveCount = 0.obs;
  final totalHoursToday = 0.0.obs;
  final totalLabourCostToday = 0.0.obs;

  static const double minHours = 1;
  static const double maxHours = 12;

  @override
  void onReady() {
    subscribeWorkers();
    subscribeAttendance();
    subscribeAttendancePeriod();
    super.onReady();
  }

  @override
  void onClose() {
    _labourSub?.cancel();
    _attendanceSub?.cancel();
    _attendancePeriodSub?.cancel();
    super.onClose();
  }

  void subscribeWorkers() {
    _labourSub?.cancel();
    _labourSub = _labourRepo
        .streamLabour(limit: AppConstants.defaultPageSize * 3)
        .listen((list) {
      workers.assignAll(list);
      _updateDashboard();
    }, onError: (e) {
      AppLogger.error('Attendance: workers stream error', error: e);
    });
  }

  void subscribeAttendance() {
    _attendanceSub?.cancel();
    final date = DateTime(selectedDate.value.year, selectedDate.value.month, selectedDate.value.day);
    _attendanceSub = _attendanceRepo.streamAttendanceForDate(date).listen((list) {
      attendanceForDate.assignAll(list);
      _updateDashboard();
    }, onError: (e) {
      AppLogger.error('Attendance: stream error', error: e);
    });
  }

  void subscribeAttendancePeriod() {
    _attendancePeriodSub?.cancel();
    final end = DateTime(selectedDate.value.year, selectedDate.value.month, selectedDate.value.day);
    DateTime start;
    switch (listFilter.value) {
      case AttendanceListFilter.daily:
        start = end;
        break;
      case AttendanceListFilter.weekly:
        start = end.subtract(const Duration(days: 6));
        break;
      case AttendanceListFilter.monthly:
        start = end.subtract(const Duration(days: 29));
        break;
    }
    _attendancePeriodSub = _attendanceRepo
        .streamAttendance(fromDate: start, toDate: end.add(const Duration(days: 1)), limit: 500)
        .listen((list) {
      attendanceForPeriod.assignAll(list);
    }, onError: (e) {
      AppLogger.error('Attendance: period stream error', error: e);
    });
  }

  void setSelectedDate(DateTime date) {
    selectedDate.value = DateTime(date.year, date.month, date.day);
    subscribeAttendance();
    subscribeAttendancePeriod();
  }

  void setListFilter(AttendanceListFilter filter) {
    listFilter.value = filter;
    subscribeAttendancePeriod();
  }

  void setSearchQuery(String q) {
    searchQuery.value = q.trim().toLowerCase();
  }

  void _updateDashboard() {
    totalWorkers.value = workers.length;
    presentCount.value = attendanceForDate.where((a) => a.isPresent).length;
    absentCount.value = attendanceForDate.where((a) => a.isAbsent).length;
    leaveCount.value = attendanceForDate.where((a) => a.attendanceType == AttendanceType.leave).length;
    totalHoursToday.value = attendanceForDate.fold<double>(0, (s, a) => s + a.totalHours);
    totalLabourCostToday.value = 0;
    for (final a in attendanceForDate) {
      final worker = workers.where((w) => w.id == a.workerId).firstOrNull;
      if (worker != null) {
        totalLabourCostToday.value += PaymentCalculator.paymentForAttendance(attendance: a, worker: worker);
      }
    }
  }

  /// Pending = workers who do NOT have attendance for selected date. Filtered by search.
  List<LabourModel> get pendingWorkers {
    final markedIds = attendanceForDate.map((a) => a.workerId).toSet();
    var list = workers.where((w) => !markedIds.contains(w.id)).toList();
    final q = searchQuery.value;
    if (q.isNotEmpty) {
      list = list.where((w) {
        final name = w.name.toLowerCase();
        final phone = (w.phone ?? '').toLowerCase();
        final labourType = w.labourType.displayName.toLowerCase();
        return name.contains(q) || phone.contains(q) || labourType.contains(q);
      }).toList();
    }
    return list;
  }

  /// Present list for selected period (daily = selected date only; weekly/monthly = range).
  List<AttendanceModel> get presentWorkers {
    if (listFilter.value == AttendanceListFilter.daily) {
      return attendanceForDate.where((a) => a.isPresent).toList();
    }
    return attendanceForPeriod.where((a) => a.isPresent).toList();
  }

  /// Absent list for selected period.
  List<AttendanceModel> get absentWorkers {
    if (listFilter.value == AttendanceListFilter.daily) {
      return attendanceForDate.where((a) => a.isAbsent).toList();
    }
    return attendanceForPeriod.where((a) => a.isAbsent).toList();
  }

  AttendanceModel? getAttendanceForWorker(String workerId) {
    return attendanceForDate.where((a) => a.workerId == workerId).firstOrNull;
  }

  LabourModel? getWorker(String workerId) {
    return workers.where((w) => w.id == workerId).firstOrNull;
  }

  /// Mark present: open dialog in view; view calls this with dialog result. Prevents duplicate.
  Future<bool> markPresent(
    LabourModel worker, {
    required double hoursWorked,
    required bool overtimeEnabled,
    double overtimeAmount = 0,
  }) async {
    saveError.value = null;
    final date = selectedDate.value;
    final existing = await _attendanceRepo.getByWorkerAndDate(worker.id, date);
    if (existing != null) {
      AppLogger.calc('Duplicate attendance prevented: worker ${worker.id} already has record for date');
      saveError.value = 'Already marked for this date';
      return false;
    }
    if (hoursWorked < minHours || hoursWorked > maxHours) {
      saveError.value = 'Hours must be between $minHours and $maxHours';
      return false;
    }
    if (overtimeEnabled && overtimeAmount < 0) {
      saveError.value = 'Overtime amount cannot be negative';
      return false;
    }
    final now = DateTime.now();
    final model = AttendanceModel(
      id: _uuid.v4(),
      workerId: worker.id,
      date: date,
      hoursWorked: hoursWorked.clamp(minHours, maxHours),
      overtimeHours: 0,
      attendanceType: overtimeEnabled ? AttendanceType.overtime : AttendanceType.present,
      attendanceStatus: AttendanceStatus.present,
      overtimeEnabled: overtimeEnabled,
      overtimeAmount: overtimeEnabled ? overtimeAmount.clamp(0.0, double.infinity) : 0,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _attendanceRepo.addAttendance(model);
      AppLogger.calc('Marking worker present | Worker ID: ${worker.id} | Hours: $hoursWorked | Overtime: $overtimeAmount');
      final payment = PaymentCalculator.paymentForAttendance(attendance: model, worker: worker);
      AppLogger.calc('Payment calculated: $payment');
      return true;
    } catch (e, st) {
      AppLogger.error('Firestore write failed', error: e, stackTrace: st);
      saveError.value = 'Failed to save: ${e.toString()}';
      return false;
    }
  }

  /// Mark absent. Prevents duplicate.
  Future<bool> markAbsent(LabourModel worker) async {
    saveError.value = null;
    final date = selectedDate.value;
    final existing = await _attendanceRepo.getByWorkerAndDate(worker.id, date);
    if (existing != null) {
      AppLogger.calc('Duplicate attendance prevented: worker ${worker.id}');
      saveError.value = 'Already marked for this date';
      return false;
    }
    final now = DateTime.now();
    final model = AttendanceModel(
      id: _uuid.v4(),
      workerId: worker.id,
      date: date,
      hoursWorked: 0,
      overtimeHours: 0,
      attendanceType: AttendanceType.absent,
      attendanceStatus: AttendanceStatus.absent,
      overtimeEnabled: false,
      overtimeAmount: 0,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _attendanceRepo.addAttendance(model);
      AppLogger.calc('Marking worker absent | Worker ID: ${worker.id}');
      return true;
    } catch (e, st) {
      AppLogger.error('Firestore write failed', error: e, stackTrace: st);
      saveError.value = 'Failed to save: ${e.toString()}';
      return false;
    }
  }

  /// Legacy: quick cycle (kept for any existing usage). Prefer markPresent/markAbsent for day-wise flow.
  Future<void> markAttendance(LabourModel worker) async {
    final existing = getAttendanceForWorker(worker.id);
    if (existing != null) return;
    await markAbsent(worker);
  }

  /// Update an existing attendance record (correction flow). Same document is updated; streams refresh UI.
  /// Validates: hours 1-12 if present, overtimeAmount >= 0. Returns false and sets saveError on failure.
  Future<bool> updateAttendanceRecord(
    AttendanceModel existing, {
    required AttendanceStatus newStatus,
    double? hoursWorked,
    bool? overtimeEnabled,
    double? overtimeAmount,
  }) async {
    saveError.value = null;
    if (existing.id.isEmpty) {
      saveError.value = 'Invalid attendance record';
      return false;
    }
    if (newStatus == AttendanceStatus.present) {
      final rawHours = hoursWorked ?? existing.hoursWorked;
      if (rawHours < minHours || rawHours > maxHours) {
        saveError.value = 'Hours must be between $minHours and $maxHours';
        return false;
      }
      final otEnabled = overtimeEnabled ?? existing.overtimeEnabled;
      final rawOtAmount = overtimeAmount ?? existing.overtimeAmount;
      if (otEnabled && rawOtAmount < 0) {
        saveError.value = 'Overtime amount cannot be negative';
        return false;
      }
    }

    final oldStatus = existing.attendanceStatus ?? (existing.isPresent ? AttendanceStatus.present : AttendanceStatus.absent);
    final isPresentNow = newStatus == AttendanceStatus.present;
    final hours = isPresentNow
        ? (hoursWorked ?? existing.hoursWorked).clamp(minHours, maxHours)
        : 0.0;
    final otEnabled = isPresentNow ? (overtimeEnabled ?? existing.overtimeEnabled) : false;
    final otAmount = isPresentNow && otEnabled
        ? (overtimeAmount ?? existing.overtimeAmount).clamp(0.0, double.infinity)
        : 0.0;
    final newType = isPresentNow
        ? (otEnabled ? AttendanceType.overtime : AttendanceType.present)
        : AttendanceType.absent;

    AppLogger.calc('Editing attendance for worker: ${existing.workerId}');
    AppLogger.calc('Old Status: ${oldStatus.name}');
    AppLogger.calc('New Status: ${newStatus.name}');
    if (isPresentNow) AppLogger.calc('Updated hours: $hours');

    final updated = existing.copyWith(
      attendanceStatus: newStatus,
      attendanceType: newType,
      hoursWorked: hours,
      overtimeHours: isPresentNow ? 0 : 0,
      overtimeEnabled: otEnabled,
      overtimeAmount: otAmount,
      updatedAt: DateTime.now(),
    );

    try {
      await _attendanceRepo.updateAttendance(updated);
      final worker = getWorker(existing.workerId);
      if (worker != null) {
        final payment = PaymentCalculator.paymentForAttendance(attendance: updated, worker: worker);
        AppLogger.calc('Payment recalculated: $payment');
      }
      return true;
    } catch (e, st) {
      AppLogger.error('Firestore update failed', error: e, stackTrace: st);
      saveError.value = 'Failed to update: ${e.toString()}';
      return false;
    }
  }

  /// Create or update attendance with check-in/check-out (legacy detail sheet).
  Future<void> updateAttendance(LabourModel worker, {String? checkIn, String? checkOut, String? notes}) async {
    final date = selectedDate.value;
    final existing = await _attendanceRepo.getByWorkerAndDate(worker.id, date);
    final (regular, overtime) = AttendanceService.calculateHoursAndOvertime(
      checkInTime: checkIn ?? existing?.checkInTime,
      checkOutTime: checkOut ?? existing?.checkOutTime,
    );
    final type = overtime > 0 ? AttendanceType.overtime : AttendanceType.present;
    final model = AttendanceModel(
      id: existing?.id ?? _uuid.v4(),
      workerId: worker.id,
      date: date,
      checkInTime: checkIn ?? existing?.checkInTime,
      checkOutTime: checkOut ?? existing?.checkOutTime,
      hoursWorked: AttendanceService.clampHours(regular),
      overtimeHours: AttendanceService.clampOvertime(overtime),
      attendanceType: type,
      attendanceStatus: AttendanceStatus.present,
      overtimeEnabled: overtime > 0,
      overtimeAmount: overtime > 0 ? (worker.hourlyRate ?? 0) * overtime : 0,
      notes: notes ?? existing?.notes,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (existing != null) {
      await _attendanceRepo.updateAttendance(model);
    } else {
      await _attendanceRepo.addAttendance(model);
    }
    subscribeAttendance();
  }

  (double regular, double overtime) calculateHours({String? checkIn, String? checkOut}) {
    return AttendanceService.calculateHoursAndOvertime(checkInTime: checkIn, checkOutTime: checkOut);
  }

  double calculateOvertime(double totalHours) {
    return AttendanceService.calculateOvertime(totalHours).$2;
  }
}
