import '../constants/app_strings.dart';

/// Reusable form validators for the app.
class FormValidators {
  FormValidators._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.validationRequired;
    return null;
  }

  static String? requiredDouble(String? value, {bool allowZero = false}) {
    if (value == null || value.trim().isEmpty) return AppStrings.validationRequired;
    final n = double.tryParse(value.trim());
    if (n == null) return AppStrings.validationRequired;
    if (!allowZero && n <= 0) return AppStrings.validationQuantityPositive;
    if (allowZero && n < 0) return AppStrings.validationPriceNonNegative;
    return null;
  }

  static String? quantity(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.validationRequired;
    final n = double.tryParse(value.trim());
    if (n == null) return AppStrings.validationRequired;
    if (n <= 0) return AppStrings.validationQuantityPositive;
    return null;
  }

  static String? priceOrAmount(String? value, {bool allowZero = false}) {
    if (value == null || value.trim().isEmpty) return AppStrings.validationRequired;
    final n = double.tryParse(value.trim());
    if (n == null) return AppStrings.validationRequired;
    if (!allowZero && n <= 0) return AppStrings.validationAmountPositive;
    if (allowZero && n < 0) return AppStrings.validationPriceNonNegative;
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) return AppStrings.validationPhoneDigits;
    return null;
  }

  static String? workHoursOrRate(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.validationRequired;
    final n = double.tryParse(value.trim());
    if (n == null) return AppStrings.validationRequired;
    if (n <= 0) return AppStrings.validationRatePositive;
    return null;
  }
}
