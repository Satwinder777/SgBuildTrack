/// Reusable calculation helpers for BuildLedger.
class CalculationHelpers {
  CalculationHelpers._();

  /// total_price = quantity × price_per_unit
  static double calculateMaterialCost(double quantity, double pricePerUnit) {
    return quantity * pricePerUnit;
  }

  /// total_payment = work_hours × hourly_rate
  static double calculateLabourHourly(double hours, double rate) {
    return hours * rate;
  }

  /// total_payment = fixed_day_rate (single day)
  static double calculateLabourFixed(double rate) {
    return rate;
  }

  /// pending_amount = total_amount − paid_amount
  static double calculatePendingAmount(double total, double paid) {
    return (total - paid).clamp(0, double.infinity);
  }

  /// Predict future cost: previousCost * (1 + growthRate/100)
  static double predictFutureCost(double previousCost, double growthRatePercent) {
    return previousCost * (1 + (growthRatePercent / 100));
  }

  /// Sum of a list of numbers.
  static double sum(Iterable<double> values) {
    return values.fold(0.0, (a, b) => a + b);
  }
}
