import 'package:flutter/material.dart';

/// Centralized color palette for BuildLedger – Material 3 inspired.
class AppColors {
  AppColors._();

  // Primary – construction/earthy
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);

  // Secondary – accent
  static const Color secondary = Color(0xFFF9A825);
  static const Color secondaryLight = Color(0xFFFFD95A);
  static const Color secondaryDark = Color(0xFFC17900);

  // Surface & background
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceVariant = Color(0xFFE8E8E8);
  static const Color background = Color(0xFFFAFAFA);

  // Card & elevation
  static const Color card = Colors.white;
  static const Color cardShadow = Color(0x1A000000);

  // Semantic
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);

  // Text
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textOnPrimary = Colors.white;

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient dashboardHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B5E20),
      Color(0xFF2E7D32),
      Color(0xFF43A047),
    ],
  );
}
