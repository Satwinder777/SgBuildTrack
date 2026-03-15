import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/helper_functions/format_helpers.dart';
import '../../../data/models/labour_model.dart';
import '../controllers/worker_payment_controller.dart';

class WorkerPaymentView extends GetView<WorkerPaymentController> {
  const WorkerPaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Payments'),
      ),
      body: Obx(() {
        if (controller.workers.isEmpty) {
          return const Center(
            child: Text('Add workers from Labour module to see payment summary'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.workers.length,
          itemBuilder: (_, i) {
            final worker = controller.workers[i];
            final summary = controller.summaryForWorker(worker);
            return _WorkerPaymentCard(
              summary: summary,
              onPayNow: () => _showPayDialog(worker),
              onViewHistory: () => _showHistory(worker.id),
            );
          },
        );
      }),
    );
  }

  void _showPayDialog(LabourModel worker) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text('Pay ${worker.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              final ok = await controller.payNow(worker, amount, notesController.text);
              if (ok) {
                Get.back();
              } else if (controller.saveError.value != null) {
                Get.snackbar('Error', controller.saveError.value ?? '');
              }
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    ).then((e){
      controller.workers.refresh();
    });
  }

  void _showHistory(String workerId) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Payment History',
              style: Get.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Obx(() {
              final list = controller.paymentHistoryForWorker(workerId);
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No payments yet')),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  return ListTile(
                    title: Text(FormatHelpers.formatCurrency(p.amountPaid)),
                    subtitle: Text(
                      '${p.paymentDate.day}/${p.paymentDate.month}/${p.paymentDate.year}${p.notes != null ? ' • ${p.notes}' : ''}',
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _WorkerPaymentCard extends StatelessWidget {
  const _WorkerPaymentCard({
    required this.summary,
    required this.onPayNow,
    required this.onViewHistory,
  });

  final WorkerPaymentSummary summary;
  final VoidCallback onPayNow;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final worker = summary.worker;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Get.theme.colorScheme.primaryContainer,
                  child: Text(
                    worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                    style: TextStyle(color: Get.theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        worker.labourType.displayName,
                        style: Get.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _RowLabel('Total earnings', FormatHelpers.formatCurrency(summary.totalEarnings)),
            _RowLabel('Total paid', FormatHelpers.formatCurrency(summary.totalPaid)),
            _RowLabel('Pending', FormatHelpers.formatCurrency(summary.pending),
                highlight: summary.pending > 0),
            _RowLabel('Hours', summary.totalHours.toStringAsFixed(1)),
            _RowLabel('Working days', '${summary.workingDays}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewHistory,
                    icon: const Icon(Icons.history, size: 20),
                    label: const Text('History'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: summary.pending > 0 ? onPayNow : null,
                    icon: const Icon(Icons.payment, size: 20),
                    label: const Text('Pay Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Get.textTheme.bodyMedium),
          Text(
            value,
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? Get.theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}
