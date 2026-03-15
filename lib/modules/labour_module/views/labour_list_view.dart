import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/date_filter.dart';
import '../../../core/helper_functions/format_helpers.dart';
import '../../../data/models/labour_model.dart';
import '../../../routes/app_routes.dart';
import '../../../presentation/widgets/empty_state_widget.dart';
import '../controllers/labour_controller.dart';

class LabourListView extends GetView<LabourController> {
  const LabourListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.labour)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, type or amount',
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
              if (controller.isLoading.value && controller.labourList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.labourList.isEmpty) {
                return EmptyStateWidget(
                  title: AppStrings.noData,
                  subtitle: AppStrings.tapToAdd,
                  icon: Icons.engineering,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.labourList.length,
                itemBuilder: (_, i) {
                  final l = controller.labourList[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
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
                      trailing: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                FormatHelpers.formatCurrency(l.totalPayment),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(l),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),
                          ],
                        ),
                      ),
                      onTap: () => Get.toNamed(AppRoutes.labourForm, arguments: l),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'labour_fab',
        onPressed: () => Get.toNamed(AppRoutes.labourForm),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(LabourModel l) {
    Get.dialog(
      AlertDialog(
        title: const Text(AppStrings.delete),
        content: Text('Delete ${l.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              await controller.deleteLabour(l.id);
              Get.back();
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
