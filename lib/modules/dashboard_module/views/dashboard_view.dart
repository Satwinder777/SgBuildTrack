import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/helper_functions/format_helpers.dart';
import '../../../core/helper_functions/date_helpers.dart';
import '../../../data/models/material_model.dart';
import '../../../data/models/labour_model.dart';
import '../../../data/models/worker_payment_record_model.dart';
import '../../../routes/app_routes.dart';
import '../../../presentation/widgets/empty_state_widget.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/summary_card.dart';
import '../widgets/material_labour_chart.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/labour_cost_chart.dart';
import '../widgets/attendance_chart.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Obx(() {
              if (controller.loadError.value != null) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
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
              if (controller.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterChips(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppStrings.totalConstructionCost,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppStrings.materialVsLabour,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: Obx(() => MaterialLabourChart(
                      materialCost: controller.totalMaterialCost.value,
                      labourCost: controller.totalLabourEarnings,
                    )),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppStrings.labourCostChart,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: Obx(() => LabourCostChart(
                      costByDay: Map.from(controller.labourCostByDay),
                    )),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppStrings.materialCostChart,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 220,
                    child: Obx(() => CategoryBreakdownChart(
                      categoryMap: Map.from(controller.categoryCostMap),
                    )),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppStrings.attendanceChart,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: Obx(() => AttendanceChart(
                      attendanceByDay: Map.from(controller.attendanceByDay),
                    )),
                  ),
                  _sectionTitle(AppStrings.recentMaterials),
                  _recentMaterialsList(),
                  _sectionTitle(AppStrings.recentLabour),
                  _recentLabourList(),
                  _sectionTitle(AppStrings.recentWorkerPayments),
                  _recentWorkerPaymentsList(),
                  const SizedBox(height: 100),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            _filterChip(AppStrings.filterToday, DashboardFilter.today),
            const SizedBox(width: 8),
            _filterChip(AppStrings.filterThisWeek, DashboardFilter.thisWeek),
            const SizedBox(width: 8),
            _filterChip(AppStrings.filterThisMonth, DashboardFilter.thisMonth),
          ],
        ),
      );
    });
  }

  Widget _filterChip(String label, DashboardFilter value) {
    final selected = controller.filter.value == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => controller.setFilter(value),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildStatsGrid() {
    return Obx(() {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.25,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          SummaryCard(
            title: AppStrings.totalWorkers,
            amount: controller.totalWorkers.value.toDouble(),
            icon: Icons.people_outline,
            delayMs: 0,
            prefix: '',
            suffix: '',
          ),
          SummaryCard(
            title: AppStrings.presentToday,
            amount: controller.presentToday.value.toDouble(),
            icon: Icons.check_circle_outline,
            delayMs: 50,
            prefix: '',
            suffix: '',
          ),
          SummaryCard(
            title: AppStrings.absentToday,
            amount: controller.absentToday.value.toDouble(),
            icon: Icons.cancel_outlined,
            delayMs: 100,
            prefix: '',
            suffix: '',
          ),
          SummaryCard(
            title: AppStrings.totalWorkHoursToday,
            amount: controller.totalHoursToday.value,
            icon: Icons.schedule,
            delayMs: 150,
            prefix: '',
            suffix: ' hrs',
          ),
          SummaryCard(
            title: AppStrings.todayLabourCost,
            amount: controller.todayLabourCost.value,
            icon: Icons.engineering_outlined,
            delayMs: 200,
          ),
          SummaryCard(
            title: AppStrings.totalMaterialCost,
            amount: controller.totalMaterialCost.value,
            icon: Icons.inventory_2_outlined,
            delayMs: 250,
          ),
          SummaryCard(
            title: AppStrings.totalPaymentsMade,
            amount: controller.totalPaymentsMade.value,
            icon: Icons.payment,
            delayMs: 300,
          ),
          SummaryCard(
            title: AppStrings.totalPendingAmount,
            amount: controller.pendingPayments.value,
            icon: Icons.pending_actions_outlined,
            delayMs: 350,
          ),
        ],
      );
    });
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          AppStrings.appName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.dashboardHeaderGradient,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => _navigateToSection(title),
            child: const Text('View all'),
          ),
        ],
      ),
    );
  }

  void _navigateToSection(String title) {
    if (title == AppStrings.recentMaterials) Get.toNamed(AppRoutes.materials);
    if (title == AppStrings.recentLabour) Get.toNamed(AppRoutes.labour);
    if (title == AppStrings.recentWorkerPayments) Get.toNamed(AppRoutes.workerPayments);
  }

  Widget _recentMaterialsList() {
    return Obx(() {
      final list = controller.materials.take(5).toList();
      if (list.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: EmptyStateWidget(subtitle: AppStrings.tapToAdd),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final MaterialModel m = list[i];
          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.inventory_2),
            ),
            title: Text(
              m.materialName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Text(
              m.category.displayName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            trailing: Text(
              FormatHelpers.formatCurrencyCompact(m.totalPrice),
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Get.toNamed(AppRoutes.materials),
          );
        },
      );
    });
  }

  Widget _recentLabourList() {
    return Obx(() {
      final list = controller.workers.take(5).toList();
      if (list.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: EmptyStateWidget(subtitle: AppStrings.tapToAdd),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final LabourModel l = list[i];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.engineering)),
            title: Text(
              l.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Text(
              l.labourType.displayName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            trailing: Text(
              FormatHelpers.formatCurrencyCompact(l.totalPayment),
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Get.toNamed(AppRoutes.labour),
          );
        },
      );
    });
  }

  Widget _recentWorkerPaymentsList() {
    return Obx(() {
      final list = controller.workerPayments.take(5).toList();
      if (list.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: EmptyStateWidget(subtitle: AppStrings.tapToAdd),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final WorkerPaymentRecordModel p = list[i];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.payments)),
            title: Text(
              'Worker payment',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Text(
              DateHelpers.formatDate(p.paymentDate),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            trailing: Text(
              FormatHelpers.formatCurrencyCompact(p.amountPaid),
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Get.toNamed(AppRoutes.workerPayments),
          );
        },
      );
    });
  }
}
