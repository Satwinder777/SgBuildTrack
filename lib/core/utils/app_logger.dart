import 'package:flutter/foundation.dart';

/// Structured logging for the app. Use for API calls, DB operations, form submissions, errors.
/// In debug mode logs to console; can be extended to crash reporting in release.
class AppLogger {
  AppLogger._();

  static const String _tag = '[BuildLedger]';

  static void api(String message, {Map<String, dynamic>? data}) {
    _log('API', message, data: data);
  }

  static void db(String message, {Map<String, dynamic>? data}) {
    _log('DB', message, data: data);
  }

  static void form(String message, {Map<String, dynamic>? data}) {
    _log('FORM', message, data: data);
  }

  static void calc(String message, {Map<String, dynamic>? data}) {
    _log('CALC', message, data: data);
  }

  static void nav(String message, {Map<String, dynamic>? data}) {
    _log('NAV', message, data: data);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, data: error != null ? {'error': error.toString()} : null);
    if (stackTrace != null) {
      debugPrint('$_tag [ERROR] StackTrace: $stackTrace');
    }
  }

  static void _log(String level, String message, {Map<String, dynamic>? data}) {
    final buffer = StringBuffer('$_tag [$level] $message');
    if (data != null && data.isNotEmpty) {
      buffer.write(' | ${data.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
    }
    debugPrint(buffer.toString());
  }
}
