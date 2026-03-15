import 'package:intl/intl.dart';

/// Format helpers for currency, numbers, and text.
class FormatHelpers {
  FormatHelpers._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format amount as Indian Rupees (e.g. ₹1,25,000.00).
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Compact currency for cards (e.g. ₹1.2L, ₹50K).
  static String formatCurrencyCompact(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatCurrency(amount);
  }

  /// Format number with optional decimals.
  static String formatNumber(double value, {int decimals = 2}) {
    return NumberFormat('#,##0.##').format(value);
  }

  /// Format phone for display.
  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '—';
    return phone;
  }
}
