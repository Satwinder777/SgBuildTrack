import '../../core/utils/app_logger.dart';

/// Strict unit-based material cost calculation.
/// Rule: totalCost = quantity × pricePerUnit (always).
class MaterialCalculator {
  MaterialCalculator._();

  /// Calculates total cost. Use before saving to ensure correct value.
  /// Example: 1000 bricks × ₹8 = ₹8000; 50 bags × ₹420 = ₹21000.
  static double calculateMaterialCost({
    required double quantity,
    required double pricePerUnit,
  }) {
    return quantity * pricePerUnit;
  }

  /// Same as [calculateMaterialCost] with validation logs for debugging.
  static double calculateWithLogs({
    required String materialName,
    required double quantity,
    required double pricePerUnit,
    String unitLabel = '',
  }) {
    final total = calculateMaterialCost(quantity: quantity, pricePerUnit: pricePerUnit);
    AppLogger.calc(
      'Material cost',
      data: {
        'material': materialName,
        'quantity': quantity,
        'pricePerUnit': pricePerUnit,
        'unit': unitLabel,
        'total': total,
      },
    );
    return total;
  }
}
