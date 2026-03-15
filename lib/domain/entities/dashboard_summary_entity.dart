/// Aggregated summary for dashboard – material, labour, paid, pending, total.
class DashboardSummaryEntity {
  const DashboardSummaryEntity({
    required this.totalMaterialCost,
    required this.totalLabourCost,
    required this.totalPaidAmount,
    required this.totalPendingAmount,
    required this.totalConstructionCost,
  });

  final double totalMaterialCost;
  final double totalLabourCost;
  final double totalPaidAmount;
  final double totalPendingAmount;
  final double totalConstructionCost;
}
