import '../../core/helper_functions/calculation_helpers.dart';

/// Predicts future construction cost based on previous cost and growth rate.
/// Structure ready for OpenAI API integration later.
class PredictFutureCostUseCase {
  PredictFutureCostUseCase();

  /// [previousCost] – e.g. last slab cost 120000
  /// [growthRatePercent] – e.g. 10 for 10%
  /// Returns predicted amount.
  double call(double previousCost, double growthRatePercent) {
    return CalculationHelpers.predictFutureCost(previousCost, growthRatePercent);
  }
}
