import 'package:collection/collection.dart';

import '../../data/models/attendance_model.dart';
import '../../data/models/labour_model.dart';
import '../../data/models/material_model.dart';
import '../../data/models/worker_payment_record_model.dart';
import 'payment_calculator.dart';

/// Dashboard stats computed from streams. Used by DashboardController.
class DashboardCalculationService {
  DashboardCalculationService._();

  static int calculateTotalWorkers(List<LabourModel> workers) => workers.length;

  static int calculatePresentToday(List<AttendanceModel> attendanceToday) =>
      attendanceToday.where((a) => a.isPresent).length;

  static int calculateAbsentToday(List<AttendanceModel> attendanceToday) =>
      attendanceToday.where((a) => a.isAbsent).length;

  static double calculateTotalHoursToday(List<AttendanceModel> attendanceToday) =>
      attendanceToday.fold<double>(0, (s, a) => s + a.totalHours);

  /// Today's labour cost from today's attendance (hourly/daily + overtime via PaymentCalculator).
  static double calculateTodayLabourCost({
    required List<AttendanceModel> attendanceToday,
    required List<LabourModel> workers,
  }) {
    double total = 0;
    for (final a in attendanceToday) {
      final worker = workers.where((w) => w.id == a.workerId).firstOrNull;
      if (worker != null) {
        total += PaymentCalculator.paymentForAttendance(attendance: a, worker: worker);
      }
    }
    return total;
  }

  /// Total labour earnings from all attendance (for pending = earnings - payments).
  static double calculateTotalLabourEarnings({
    required List<AttendanceModel> attendance,
    required List<LabourModel> workers,
  }) {
    double total = 0;
    for (final a in attendance) {
      final worker = workers.where((w) => w.id == a.workerId).firstOrNull;
      if (worker != null) {
        total += PaymentCalculator.paymentForAttendance(attendance: a, worker: worker);
      }
    }
    return total;
  }

  /// Total material cost = sum(quantity × pricePerUnit) or sum(totalPrice).
  static double calculateTotalMaterialCost(List<MaterialModel> materials) =>
      materials.fold<double>(0, (s, m) => s + (m.totalPrice));

  /// Total payments made to workers.
  static double calculateTotalPaymentsMade(List<WorkerPaymentRecordModel> workerPayments) =>
      workerPayments.fold<double>(0, (s, p) => s + p.amountPaid);

  /// Pending = total labour earnings - total payments made.
  static double calculatePendingPayments({
    required double totalLabourEarnings,
    required double totalPaymentsMade,
  }) =>
      (totalLabourEarnings - totalPaymentsMade).clamp(0.0, double.infinity);

  /// Category-wise material cost for chart.
  static Map<String, double> calculateMaterialCostByCategory(List<MaterialModel> materials) {
    final map = <String, double>{};
    for (final m in materials) {
      final key = m.category.displayName;
      map[key] = (map[key] ?? 0) + m.totalPrice;
    }
    return map;
  }

  /// Labour cost per day for a date range (for Labour Cost Chart). Keys are date-only.
  static Map<DateTime, double> calculateLabourCostByDay({
    required List<AttendanceModel> attendance,
    required List<LabourModel> workers,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final map = <DateTime, double>{};
    for (final a in attendance) {
      final d = DateTime(a.date.year, a.date.month, a.date.day);
      if (d.isBefore(start) || d.isAfter(end)) continue;
      final worker = workers.where((w) => w.id == a.workerId).firstOrNull;
      if (worker != null) {
        map[d] = (map[d] ?? 0) + PaymentCalculator.paymentForAttendance(attendance: a, worker: worker);
      }
    }
    return map;
  }

  /// Present and absent count per day for a date range (for Attendance Chart).
  static Map<DateTime, ({int present, int absent})> calculateAttendanceByDay({
    required List<AttendanceModel> attendance,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final map = <DateTime, ({int present, int absent})>{};
    for (final a in attendance) {
      final d = DateTime(a.date.year, a.date.month, a.date.day);
      if (d.isBefore(start) || d.isAfter(end)) continue;
      final current = map[d] ?? (present: 0, absent: 0);
      if (a.isPresent) {
        map[d] = (present: current.present + 1, absent: current.absent);
      } else {
        map[d] = (present: current.present, absent: current.absent + 1);
      }
    }
    return map;
  }
}
