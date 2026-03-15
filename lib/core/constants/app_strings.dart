/// Centralized strings for BuildLedger.
class AppStrings {
  AppStrings._();

  static const String appName = 'SherGill Home Manager';
  static const String dashboard = 'Dashboard';
  static const String materials = 'Materials';
  static const String labour = 'Labour';
  static const String attendance = 'Attendance';
  static const String workerPayments = 'Worker Payments';
  static const String reports = 'Reports';
  static const String settings = 'Settings';
  static const String aiPrediction = 'AI Prediction';
  static const String recentWorkerPayments = 'Recent Worker Payments';

  // Dashboard
  static const String totalWorkers = 'Total Workers';
  static const String presentToday = 'Present Today';
  static const String absentToday = 'Absent Today';
  static const String totalWorkHoursToday = 'Total Work Hours Today';
  static const String todayLabourCost = 'Today Labour Cost';
  static const String totalMaterialCost = 'Total Material Cost';
  static const String totalLabourCost = 'Total Labour Cost';
  static const String totalPaymentsMade = 'Total Payments Made';
  static const String totalPaidAmount = 'Total Paid Amount';
  static const String totalPendingAmount = 'Total Pending Amount';
  static const String totalConstructionCost = 'Total Construction Cost';
  static const String recentMaterials = 'Recent Materials';
  static const String recentLabour = 'Recent Labour';
  static const String recentPayments = 'Recent Payments';
  static const String materialVsLabour = 'Material vs Labour';
  static const String categoryBreakdown = 'Category Cost Breakdown';
  static const String labourCostChart = 'Labour Cost';
  static const String materialCostChart = 'Material Cost';
  static const String attendanceChart = 'Attendance';
  static const String filterToday = 'Today';
  static const String filterThisWeek = 'This Week';
  static const String filterThisMonth = 'This Month';

  // Materials
  static const String addMaterial = 'Add Material';
  static const String editMaterial = 'Edit Material';
  static const String materialHistory = 'Material History';
  static const String searchMaterial = 'Search material...';
  static const String filterByCategory = 'Filter by category';
  static const String filterByDate = 'Filter by date';
  static const String category = 'Category';
  static const String materialName = 'Material Name';
  static const String quantity = 'Quantity';
  static const String unit = 'Unit';
  static const String pricePerUnit = 'Price per unit';
  static const String totalPrice = 'Total Price';
  static const String supplierName = 'Supplier Name';
  static const String supplierPhone = 'Supplier Phone';
  static const String purchaseDate = 'Purchase Date';
  static const String billImage = 'Bill Image';
  static const String notes = 'Notes';

  // Material categories
  static const String foundationMaterial = 'Foundation Material';
  static const String brick = 'Brick';
  static const String cement = 'Cement';
  static const String sand = 'Sand';
  static const String aggregate = 'Aggregate (Bajri)';
  static const String steel = 'Steel (Sariya)';
  static const String slabMaterial = 'Slab Material';
  static const String plasterMaterial = 'Plaster Material';
  static const String flooring = 'Flooring';
  static const String doors = 'Doors';
  static const String windows = 'Windows';
  static const String other = 'Other';

  // Labour
  static const String addLabour = 'Add Labour';
  static const String editLabour = 'Edit Labour';
  static const String labourType = 'Labour Type';
  static const String hourlyRate = 'Hourly Rate';
  static const String fixedDayRate = 'Fixed Day Rate';
  static const String workHours = 'Work Hours';
  static const String totalPayment = 'Total Payment';
  static const String name = 'Name';
  static const String phone = 'Phone';
  static const String address = 'Address';
  static const String date = 'Date';
  static const String hourly = 'Hourly';
  static const String fixed = 'Fixed';
  static const String mason = 'Mason';
  static const String bricklayer = 'Bricklayer';
  static const String helper = 'Helper';
  static const String painter = 'Painter';
  static const String carpenter = 'Carpenter';
  static const String electrician = 'Electrician';
  static const String plumber = 'Plumber';

  // Payments
  static const String addPayment = 'Add Payment';
  static const String editPayment = 'Edit Payment';
  static const String clearPayment = 'Clear Payment';
  static const String paymentHistory = 'Payment History';
  static const String personName = 'Person Name';
  static const String personType = 'Person Type';
  static const String totalAmount = 'Total Amount';
  static const String paidAmount = 'Paid Amount';
  static const String pendingAmount = 'Pending Amount';
  static const String paymentStatus = 'Payment Status';
  static const String paid = 'Paid';
  static const String partial = 'Partial';
  static const String pending = 'Pending';
  static const String labourLabel = 'Labour';
  static const String supplier = 'Supplier';
  static const String contractor = 'Contractor';

  // Reports
  static const String reportsOverview = 'Overview';
  static const String attendanceReport = 'Attendance Report';
  static const String labourCostReport = 'Labour Cost Report';
  static const String paymentReport = 'Payment Report';
  static const String materialUsageReport = 'Material Usage Report';
  static const String presentCount = 'Present';
  static const String absentCount = 'Absent';
  static const String attendancePercentage = 'Attendance %';
  static const String pendingLabourPayments = 'Pending Labour';
  static const String topMaterialsUsed = 'Top Materials';
  static const String materialPurchaseTrends = 'Purchase Trends';
  static const String filterCustomRange = 'Custom Range';
  static const String searchReports = 'Search by worker, material, amount...';
  static const String totalConstructionExpense = 'Total Construction Expense';
  static const String materialExpense = 'Material Expense';
  static const String labourExpense = 'Labour Expense';
  static const String monthlyExpense = 'Monthly Expense';
  static const String categoryWiseExpense = 'Category-wise Expense';
  static const String exportPdf = 'Export to PDF';

  // AI Prediction
  static const String predictCost = 'Predict Cost';
  static const String predictedAmount = 'Predicted Amount';
  static const String growthRate = 'Growth Rate (%)';
  static const String previousCost = 'Previous Cost';

  // Common
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String search = 'Search';
  static const String noData = 'No data yet';
  static const String tapToAdd = 'Tap + to add';
  static const String emptyState = 'Nothing here yet';

  // Validation
  static const String validationRequired = 'This field is required';
  static const String validationSelectDate = 'Please select a date';
  static const String validationQuantityPositive = 'Quantity must be greater than 0';
  static const String validationPriceNonNegative = 'Price must be 0 or greater';
  static const String validationAmountPositive = 'Amount must be greater than 0';
  static const String validationPaidAmountValid = 'Paid amount cannot exceed total amount';
  static const String validationPhoneDigits = 'Enter a valid phone number (digits only, 10–15 digits)';
  static const String validationWorkHoursPositive = 'Work hours must be greater than 0';
  static const String validationRatePositive = 'Rate must be greater than 0';
  static const String validationPreviousCostPositive = 'Previous cost must be greater than 0';
}
