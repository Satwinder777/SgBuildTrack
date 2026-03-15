import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/date_filter.dart';
import '../../../core/helper_functions/format_helpers.dart';
import '../../../core/helper_functions/date_helpers.dart';
import '../../../data/models/material_model.dart';
import '../../../routes/app_routes.dart';
import '../../../presentation/widgets/empty_state_widget.dart';
import '../controllers/materials_controller.dart';

class MaterialsListView extends GetView<MaterialsController> {
  const MaterialsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.materials),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, category or amount',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: controller.setSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: DateFilterType.values.map((type) {
                  final selected = controller.dateFilterType.value == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type.label),
                      selected: selected,
                      onSelected: (_) => controller.setDateFilter(type),
                    ),
                  );
                }).toList(),
              ),
            )),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.materials.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.materials.isEmpty) {
                return EmptyStateWidget(
                  title: AppStrings.noData,
                  subtitle: AppStrings.tapToAdd,
                  icon: Icons.inventory_2_outlined,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.materials.length,
                itemBuilder: (_, i) {
                  final m = controller.materials[i];
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(m.id),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    builder: (_, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: _MaterialTile(
                      material: m,
                      onTap: () => Get.toNamed(
                        AppRoutes.materialForm,
                        arguments: m,
                      ),
                      onDelete: () => _confirmDelete(m),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'materials_fab',
        onPressed: () => Get.toNamed(AppRoutes.materialForm,arguments: null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilters() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.filterByCategory,
              style: Get.textTheme.titleSmall,
            ),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: controller.selectedCategory.value == null,
                  onSelected: (_) {
                    controller.setCategoryFilter(null);
                    Get.back();
                  },
                ),
                ...MaterialCategory.values.map((c) => ChoiceChip(
                      label: Text(c.displayName.length > 12
                          ? '${c.displayName.substring(0, 12)}..'
                          : c.displayName),
                      selected: controller.selectedCategory.value == c.name,
                      onSelected: (_) {
                        controller.setCategoryFilter(c.name);
                        Get.back();
                      },
                    )),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                controller.clearFilters();
                Get.back();
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmDelete(MaterialModel m) {
    Get.dialog(
      AlertDialog(
        title: const Text(AppStrings.delete),
        content: Text('Delete ${m.materialName}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              await controller.deleteMaterial(m.id);
              Get.back();
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({
    required this.material,
    required this.onTap,
    required this.onDelete,
  });

  final MaterialModel material;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          child: Icon(Icons.inventory_2, color: Get.theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(
          material.materialName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Text(
          '${material.category.displayName} • ${material.unitType.displayName} • ${DateHelpers.formatDate(material.purchaseDate)}',
          style: Get.textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  FormatHelpers.formatCurrency(material.totalPrice),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Get.theme.colorScheme.primary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
