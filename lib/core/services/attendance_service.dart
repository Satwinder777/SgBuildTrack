/// Auto hours and overtime calculation. Max 16 total hours, max 8 overtime.
class AttendanceService {
  AttendanceService._();

  static const double maxHoursPerDay = 16;
  static const double maxOvertimeHours = 8;
  static const double fullDayHours = 8;

  /// Parse "09:00" / "17:30" to minutes since midnight. Returns null if invalid.
  static int? timeToMinutes(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.trim().split(RegExp(r'[:\s]'));
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  /// Minutes to "HH:mm" string.
  static String minutesToTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Total hours between checkIn and checkOut. Returns 0 if invalid.
  static double calculateHoursWorked({
    String? checkInTime,
    String? checkOutTime,
  }) {
    final inM = timeToMinutes(checkInTime);
    final outM = timeToMinutes(checkOutTime);
    if (inM == null || outM == null || outM <= inM) return 0;
    final totalMinutes = (outM - inM).clamp(0, (maxHoursPerDay * 60).toInt());
    return totalMinutes / 60.0;
  }

  /// Split total hours into regular (max 8) and overtime (remainder, max 8).
  /// Returns (regularHours, overtimeHours).
  static (double regular, double overtime) calculateOvertime(double totalHours) {
    final clamped = totalHours.clamp(0.0, maxHoursPerDay);
    if (clamped <= fullDayHours) {
      return (clamped, 0.0);
    }
    final overtime = (clamped - fullDayHours).clamp(0.0, maxOvertimeHours);
    return (fullDayHours, overtime);
  }

  /// Combined: from check-in/out get (regularHours, overtimeHours).
  static (double regular, double overtime) calculateHoursAndOvertime({
    String? checkInTime,
    String? checkOutTime,
  }) {
    final total = calculateHoursWorked(checkInTime: checkInTime, checkOutTime: checkOutTime);
    return calculateOvertime(total);
  }

  static double clampHours(double hours) {
    return hours.clamp(0.0, maxHoursPerDay);
  }

  static double clampOvertime(double overtime) {
    return overtime.clamp(0.0, maxOvertimeHours);
  }
}
