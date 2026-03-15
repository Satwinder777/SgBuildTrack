/// Time parsing and formatting for attendance (HH:mm, minutes since midnight).
class TimeUtils {
  TimeUtils._();

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

  /// Minutes since midnight to "HH:mm".
  static String minutesToTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Total hours between two "HH:mm" strings.
  static double hoursBetween(String? start, String? end) {
    final startM = timeToMinutes(start);
    final endM = timeToMinutes(end);
    if (startM == null || endM == null || endM <= startM) return 0;
    return (endM - startM) / 60.0;
  }
}
