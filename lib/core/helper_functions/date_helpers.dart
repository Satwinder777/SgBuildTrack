import 'package:intl/intl.dart';

/// Date formatting and parsing helpers.
class DateHelpers {
  DateHelpers._();

  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _displayWithTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _firestoreFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');

  /// Display date: 14 Mar 2025
  static String formatDate(DateTime? date) {
    if (date == null) return '—';
    return _displayFormat.format(date);
  }

  /// Display with time: 14 Mar 2025, 02:30 PM
  static String formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return _displayWithTime.format(date);
  }

  /// For Firestore storage: yyyy-MM-dd
  static String toFirestoreDate(DateTime date) {
    return _firestoreFormat.format(date);
  }

  /// Parse from Firestore string or DateTime.
  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Month year: Mar 2025
  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  /// Start of month for filtering.
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// End of month for filtering.
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }
}
