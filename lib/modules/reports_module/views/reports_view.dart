import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/helper_functions/format_helpers.dart';
import '../../../presentation/widgets/animated_card.dart';
import '../../../presentation/widgets/animated_counter.dart';
import '../../../presentation/widgets/empty_state_widget.dart';
import '../../../data/models/material_model.dart';
import '../../dashboard_module/widgets/labour_cost_chart.dart';
import '../../dashboard_module/widgets/attendance_chart.dart';
import '../../dashboard_module/widgets/category_breakdown_chart.dart';
import '../controllers/reports_controller.dart';

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshStreams(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loadError.value != null) {
          return _buildErrorState();
        }
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            SliverToBoxAdapter(child: _buildOverviewSection()),
            SliverToBoxAdapter(child: _buildAttendanceSection()),
            SliverToBoxAdapter(child: _buildLabourCostSection()),
            SliverToBoxAdapter(child: _buildPaymentSection()),
            SliverToBoxAdapter(child: _buildMaterialSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      }),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              controller.loadError.value ?? '',
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => controller.refreshStreams(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: (v) => controller.setSearch(v),
        decoration: InputDecoration(
          hintText: AppStrings.searchReports,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(AppStrings.filterToday, ReportsFilter.today),
            const SizedBox(width: 8),
            _filterChip(AppStrings.filterThisWeek, ReportsFilter.thisWeek),
            const SizedBox(width: 8),
            _filterChip(AppStrings.filterThisMonth, ReportsFilter.thisMonth),
            const SizedBox(width: 8),
            _filterChip(AppStrings.filterCustomRange, ReportsFilter.custom),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, ReportsFilter value) {
    final selected = controller.filter.value == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        if (value == ReportsFilter.custom) {
          _showCustomDateDialog();
        } else {
          controller.setFilter(value);
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  void _showCustomDateDialog() {
    DateTime start = controller.filterDateRange.$1;
    DateTime end = controller.filterDateRange.$2;
    showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: start, end: end),
    ).then((range) {
      if (range != null) {
        controller.setCustomDateRange(range.start, range.end);
      }
    });
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(AppStrings.reportsOverview),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            AnimatedCard(
              delayMs: 0,
              child: _reportCard(
                AppStrings.totalWorkers,
                controller.totalWorkers.value.toDouble(),
                Icons.people_outline,
                prefix: '',
              ),
            ),
            AnimatedCard(
              delayMs: 50,
              child: _reportCard(
                AppStrings.presentToday,
                controller.presentToday.value.toDouble(),
                Icons.check_circle_outline,
                prefix: '',
              ),
            ),
            AnimatedCard(
              delayMs: 100,
              child: _reportCard(
                AppStrings.absentToday,
                controller.absentToday.value.toDouble(),
                Icons.cancel_outlined,
                prefix: '',
              ),
            ),
            AnimatedCard(
              delayMs: 150,
              child: _reportCard(
                AppStrings.totalLabourCost,
                controller.totalLabourCost.value,
                Icons.engineering_outlined,
              ),
            ),
            AnimatedCard(
              delayMs: 200,
              child: _reportCard(
                AppStrings.totalMaterialCost,
                controller.totalMaterialCost.value,
                Icons.inventory_2_outlined,
              ),
            ),
            AnimatedCard(
              delayMs: 250,
              child: _reportCard(
                AppStrings.totalPaymentsMade,
                controller.totalPaymentsMade.value,
                Icons.payment,
              ),
            ),
            AnimatedCard(
              delayMs: 300,
              child: _reportCard(
                AppStrings.pendingLabourPayments,
                controller.pendingPayments.value,
                Icons.pending_actions_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _reportCard(String title, double value, IconData icon, {String prefix = '₹'}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.primaryLight.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: Get.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedCounter(
                value: value,
                style: Get.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                durationMs: 400,
                prefix: prefix,
                suffix: '',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Obx(() {
      final present = controller.periodPresent;
      final absent = controller.periodAbsent;
      final pct = controller.attendancePercentageValue;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(AppStrings.attendanceReport),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statChip(AppStrings.presentCount, present, AppColors.success),
                      _statChip(AppStrings.absentCount, absent, AppColors.error),
                      _statChip(AppStrings.attendancePercentage, pct, AppColors.info, isPercent: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Daily attendance', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: AttendanceChart(attendanceByDay: Map.from(controller.attendanceByDay)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _statChip(String label, num value, Color color, {bool isPercent = false}) {
    return Column(
      children: [
        Text(
          label,
          style: Get.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          isPercent ? '${value.toStringAsFixed(1)}%' : value.toString(),
          style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildLabourCostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(AppStrings.labourCostReport),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => SizedBox(
                  height: 220,
                  child: LabourCostChart(costByDay: Map.from(controller.labourCostByDay)),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(AppStrings.paymentReport),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statChip(AppStrings.totalPaidAmount, controller.totalPaymentsMade.value, AppColors.success),
                      _statChip(AppStrings.pendingLabourPayments, controller.pendingPayments.value, AppColors.warning),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                const Text('Payment history', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx(() {
                  final byDay = controller.paymentByDay;
                  if (byDay.isEmpty) {
                    return const SizedBox(
                      height: 160,
                      child: Center(child: Text('No payments in this period')),
                    );
                  }
                  return SizedBox(
                    height: 220,
                    child: LabourCostChart(costByDay: Map.from(byDay)),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMaterialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(AppStrings.materialUsageReport),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  'Total: ${FormatHelpers.formatCurrencyCompact(controller.totalMaterialCost.value)}',
                  style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                )),
                const SizedBox(height: 12),
                const Text('Cost by category', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: Obx(() => CategoryBreakdownChart(categoryMap: Map.from(controller.categoryCostMap))),
                ),
                const SizedBox(height: 16),
                const Text(AppStrings.topMaterialsUsed, style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx(() {
                  final list = controller.filteredMaterials;
                  final top = list.toList()
                    ..sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
                  final top5 = top.take(5).toList();
                  if (top5.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: EmptyStateWidget(subtitle: AppStrings.noData),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: top5.length,
                    itemBuilder: (_, i) {
                      final m = top5[i];
                      return ListTile(
                        dense: true,
                        title: Text(m.materialName, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(m.category.displayName, style: Get.textTheme.bodySmall),
                        trailing: Text(
                          FormatHelpers.formatCurrencyCompact(m.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Get.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
