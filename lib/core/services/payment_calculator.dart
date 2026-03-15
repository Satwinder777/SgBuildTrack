import '../../data/models/attendance_model.dart';
import '../../data/models/labour_model.dart';

/// Calculates worker payment from attendance and labour (worker) rate.
/// Hourly: payment = hoursWorked × hourlyRate + overtimeHours × hourlyRate.
/// Daily: Full Day → dailyRate, Half Day → dailyRate/2, Absent/Leave → 0; overtime added when applicable.
class PaymentCalculator {
  PaymentCalculator._();

  /// Payment for one attendance record. [worker] has paymentMode, hourlyRate, fixedDayRate.
  /// Day-wise flow: when overtimeEnabled, adds attendance.overtimeAmount (currency).
  static double paymentForAttendance({
    required AttendanceModel attendance,
    required LabourModel worker,
  }) {
    double base;
    if (worker.paymentMode == LabourPaymentMode.hourly) {
      final rate = worker.hourlyRate ?? 0;
      base = attendance.hoursWorked * rate + (attendance.overtimeHours) * rate;
    } else {
      final dailyRate = worker.fixedDayRate ?? 0;
      switch (attendance.attendanceType) {
        case AttendanceType.fullDay:
        case AttendanceType.present:
        case AttendanceType.overtime:
          base = dailyRate;
          break;
        case AttendanceType.halfDay:
          base = dailyRate / 2;
          break;
        case AttendanceType.absent:
        case AttendanceType.leave:
          base = 0;
          break;
      }
      final overtimeRate = worker.hourlyRate ?? (dailyRate / 8);
      base += attendance.overtimeHours * overtimeRate;
    }
    // Day-wise: fixed overtime amount (currency) when overtime enabled
    if (attendance.overtimeEnabled && attendance.overtimeAmount > 0) {
      base += attendance.overtimeAmount;
    }
    return base;
  }

  /// Total earnings from a list of attendance records for the given worker.
  static double totalEarningsFromAttendance({
    required List<AttendanceModel> attendances,
    required LabourModel worker,
  }) {
    return attendances.fold<double>(
      0,
      (sum, a) => sum + paymentForAttendance(attendance: a, worker: worker),
    );
  }

  /// Pending amount = totalEarnings - totalPaid.
  static double pendingAmount({
    required double totalEarnings,
    required double totalPaid,
  }) {
    return (totalEarnings - totalPaid).clamp(0, double.infinity);
  }
}
