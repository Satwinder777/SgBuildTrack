/// Application-wide constants for BuildLedger.
class AppConstants {
  AppConstants._();

  static const String appName = 'SherGill Home Manager';
  static const String appTagline = 'Personal Construction Manager';

  // Firestore collections (single user - no auth, use fixed user id)
  static const String userId = 'default_user';
  static const String materialsCollection = 'users/$userId/materials';
  static const String labourCollection = 'users/$userId/labour';
  @Deprecated('Old payments module removed; use workerPaymentsCollection only')
  static const String paymentsCollection = 'users/$userId/payments';
  static const String attendanceCollection = 'users/$userId/attendance';
  static const String workerPaymentsCollection = 'users/$userId/worker_payments';

  // Storage paths
  static const String billImagesPath = 'users/$userId/bills';

  // Pagination
  static const int defaultPageSize = 20;
  static const int dashboardRecentLimit = 5;

  // Animation durations
  static const int animationShortMs = 200;
  static const int animationMediumMs = 350;
  static const int animationLongMs = 500;
  static const int chartAnimationMs = 800;
}
