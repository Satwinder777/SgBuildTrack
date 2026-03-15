/// Preset date range filters for list screens.
enum DateFilterType {
  all,
  daily,
  weekly,
  monthly,
}

extension DateFilterTypeX on DateFilterType {
  String get label {
    switch (this) {
      case DateFilterType.all:
        return 'All';
      case DateFilterType.daily:
        return 'Today';
      case DateFilterType.weekly:
        return 'This Week';
      case DateFilterType.monthly:
        return 'This Month';
    }
  }

  /// Returns [start, end] for the current filter in local time, or null for [all].
  List<DateTime>? get range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case DateFilterType.all:
        return null;
      case DateFilterType.daily:
        return [today, today.add(const Duration(days: 1))];
      case DateFilterType.weekly:
        final weekday = now.weekday;
        final start = today.subtract(Duration(days: weekday - 1));
        return [start, start.add(const Duration(days: 7))];
      case DateFilterType.monthly:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return [start, end];
    }
  }
}
