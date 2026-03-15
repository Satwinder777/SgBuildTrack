import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/helper_functions/format_helpers.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/labour_model.dart';
import '../controllers/attendance_controller.dart';

class AttendanceView extends GetView<AttendanceController> {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: controller.selectedDate.value,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) controller.setSelectedDate(d);
            },
          ),
        ],
      ),
      body: Obx(() {
        final date = controller.selectedDate.value;
        final dateStr = '${date.day}/${date.month}/${date.year}';
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Date: $dateStr',
                          style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Icon(Icons.today, color: Get.theme.colorScheme.primary),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDashboard(),
                    const SizedBox(height: 20),
                    Text(
                      'Pending Workers',
                      style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildSearchField(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildPendingList(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Present',
                      style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      filter: AttendanceListFilter.daily,
                      label: 'Daily',
                      current: controller.listFilter.value,
                      onTap: () => controller.setListFilter(AttendanceListFilter.daily),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      filter: AttendanceListFilter.weekly,
                      label: 'Weekly',
                      current: controller.listFilter.value,
                      onTap: () => controller.setListFilter(AttendanceListFilter.weekly),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      filter: AttendanceListFilter.monthly,
                      label: 'Monthly',
                      current: controller.listFilter.value,
                      onTap: () => controller.setListFilter(AttendanceListFilter.monthly),
                    ),
                  ],
                ),
              ),
            ),
            _buildPresentList(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Absent',
                  style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            _buildAbsentList(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      }),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: controller.setSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search by name, phone, labour type',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        isDense: true,
      ),
    );
  }

  Widget _buildDashboard() {
    return Obx(() => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _DashboardCard(
                    title: 'Workers',
                    value: '${controller.totalWorkers.value}',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardCard(
                    title: 'Present',
                    value: '${controller.presentCount.value}',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DashboardCard(
                    title: 'Absent',
                    value: '${controller.absentCount.value}',
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardCard(
                    title: 'Labour cost',
                    value: FormatHelpers.formatCurrency(controller.totalLabourCostToday.value),
                    icon: Icons.payments,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  Widget _buildPendingList() {
    return Obx(() {
      final pending = controller.pendingWorkers;
      if (controller.workers.isEmpty) {
        return const SliverFillRemaining(
          child: Center(child: Text('Add workers from Labour module')),
        );
      }
      if (pending.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'All workers marked for this date',
                    style: Get.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              ),
              child: _PendingWorkerCard(
                worker: pending[i],
                onSelectPresent: () => _showAddWorkDetailsDialog(pending[i]),
                onSelectAbsent: () => _markAbsent(pending[i]),
              ),
            ),
            childCount: pending.length,
          ),
        ),
      );
    });
  }

  Widget _buildPresentList() {
    return Obx(() {
      final list = controller.presentWorkers;
      if (list.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('No present records', style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final a = list[i];
              final worker = controller.getWorker(a.workerId);
              return _PresentListTile(
                attendance: a,
                workerName: worker?.name ?? '—',
                labourType: worker?.labourType.displayName ?? '—',
                onEdit: () => _showEditAttendanceDialog(a, worker),
              );
            },
            childCount: list.length,
          ),
        ),
      );
    });
  }

  Widget _buildAbsentList() {
    return Obx(() {
      final list = controller.absentWorkers;
      if (list.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('No absent records', style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final a = list[i];
              final worker = controller.getWorker(a.workerId);
              return _AbsentListTile(
                attendance: a,
                workerName: worker?.name ?? '—',
                labourType: worker?.labourType.displayName ?? '—',
                onEdit: () => _showEditAttendanceDialog(a, worker),
              );
            },
            childCount: list.length,
          ),
        ),
      );
    });
  }

  void _showAddWorkDetailsDialog(LabourModel worker) {
    Get.dialog(
      _AddWorkDetailsDialog(
        workerName: worker.name,
        onConfirm: (hoursWorked, overtimeEnabled, overtimeAmount) async {
          Get.back();
          final ok = await controller.markPresent(
            worker,
            hoursWorked: hoursWorked,
            overtimeEnabled: overtimeEnabled,
            overtimeAmount: overtimeAmount,
          );
          if (!ok && controller.saveError.value != null) {
            Get.snackbar('Error', controller.saveError.value ?? '');
          }
        },
        onCancel: () => Get.back(),
      ),
      barrierDismissible: false,
    );
  }

  void _markAbsent(LabourModel worker) async {
    final ok = await controller.markAbsent(worker);
    if (!ok && controller.saveError.value != null) {
      Get.snackbar('Error', controller.saveError.value ?? '');
    }
  }

  void _showEditAttendanceDialog(AttendanceModel attendance, LabourModel? worker) {
    Get.dialog(
      _EditAttendanceDialog(
        attendance: attendance,
        workerName: worker?.name ?? '—',
        labourType: worker?.labourType.displayName ?? '—',
        onSave: (newStatus, hoursWorked, overtimeEnabled, overtimeAmount) async {
          Get.back();
          final ok = await controller.updateAttendanceRecord(
            attendance,
            newStatus: newStatus,
            hoursWorked: hoursWorked,
            overtimeEnabled: overtimeEnabled,
            overtimeAmount: overtimeAmount,
          );
          if (!ok && controller.saveError.value != null) {
            Get.snackbar('Error', controller.saveError.value ?? '');
          }
        },
        onCancel: () => Get.back(),
      ),
      barrierDismissible: false,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.label,
    required this.current,
    required this.onTap,
  });

  final AttendanceListFilter filter;
  final String label;
  final AttendanceListFilter current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = current == filter;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.title, required this.value, required this.icon, required this.color});

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: color.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: Get.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PendingWorkerCard extends StatelessWidget {
  const _PendingWorkerCard({
    required this.worker,
    required this.onSelectPresent,
    required this.onSelectAbsent,
  });

  final LabourModel worker;
  final VoidCallback onSelectPresent;
  final VoidCallback onSelectAbsent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              child: Icon(Icons.person, color: Get.theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    worker.labourType.displayName,
                    style: Get.textTheme.bodySmall,
                  ),
                  if (worker.phone != null && worker.phone!.isNotEmpty)
                    Text(
                      worker.phone!,
                      style: Get.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: null,
                hint: const Text('Mark'),
                items: const [
                  DropdownMenuItem(value: 'present', child: Text('Present')),
                  DropdownMenuItem(value: 'absent', child: Text('Absent')),
                ],
                onChanged: (v) {
                  if (v == 'present') onSelectPresent();
                  if (v == 'absent') onSelectAbsent();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWorkDetailsDialog extends StatefulWidget {
  const _AddWorkDetailsDialog({
    required this.workerName,
    required this.onConfirm,
    required this.onCancel,
  });

  final String workerName;
  final void Function(double hoursWorked, bool overtimeEnabled, double overtimeAmount) onConfirm;
  final VoidCallback onCancel;

  @override
  State<_AddWorkDetailsDialog> createState() => _AddWorkDetailsDialogState();
}

class _AddWorkDetailsDialogState extends State<_AddWorkDetailsDialog> {
  double _hoursWorked = 8;
  bool _overtimeEnabled = false;
  final _overtimeAmountController = TextEditingController(text: '0');

  @override
  void dispose() {
    _overtimeAmountController.dispose();
    super.dispose();
  }

  void _confirm() {
    final hours = _hoursWorked.clamp(AttendanceController.minHours, AttendanceController.maxHours);
    double overtimeAmount = 0;
    if (_overtimeEnabled) {
      overtimeAmount = double.tryParse(_overtimeAmountController.text.trim()) ?? 0;
      if (overtimeAmount < 0) overtimeAmount = 0;
    }
    widget.onConfirm(hours, _overtimeEnabled, overtimeAmount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Work Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Worker: ${widget.workerName}', style: Get.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text('Hours Worked (${AttendanceController.minHours}-${AttendanceController.maxHours})',
                style: Get.textTheme.bodySmall),
            Slider(
              value: _hoursWorked,
              min: AttendanceController.minHours,
              max: AttendanceController.maxHours,
              divisions: 11,
              label: _hoursWorked.toStringAsFixed(0),
              onChanged: (v) => setState(() => _hoursWorked = v),
            ),
            Text('${_hoursWorked.toStringAsFixed(0)} hours', style: Get.textTheme.titleSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Overtime', style: Get.textTheme.bodyMedium),
                const SizedBox(width: 12),
                Switch(
                  value: _overtimeEnabled,
                  onChanged: (v) => setState(() => _overtimeEnabled = v),
                ),
              ],
            ),
            if (_overtimeEnabled) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _overtimeAmountController,
                decoration: const InputDecoration(
                  labelText: 'Overtime Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
        FilledButton(onPressed: _confirm, child: const Text('Confirm')),
      ],
    );
  }
}

class _PresentListTile extends StatelessWidget {
  const _PresentListTile({
    required this.attendance,
    required this.workerName,
    required this.labourType,
    required this.onEdit,
  });

  final AttendanceModel attendance;
  final String workerName;
  final String labourType;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final dateStr = '${attendance.date.day}/${attendance.date.month}/${attendance.date.year}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.withValues(alpha: 0.2),
            child: const Icon(Icons.check_circle, color: Colors.green),
          ),
          title: Text(workerName, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    label: Text('Present', style: TextStyle(fontSize: 11, color: Colors.green.shade800)),
                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    '$labourType • ${attendance.hoursWorked.toStringAsFixed(0)} hrs'
                    '${attendance.overtimeEnabled && attendance.overtimeAmount > 0 ? ' • OT: ${FormatHelpers.formatCurrency(attendance.overtimeAmount)}' : ''} • $dateStr',
                    style: Get.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
            tooltip: 'Edit attendance',
          ),
        ),
      ),
    );
  }
}

class _AbsentListTile extends StatelessWidget {
  const _AbsentListTile({
    required this.attendance,
    required this.workerName,
    required this.labourType,
    required this.onEdit,
  });

  final AttendanceModel attendance;
  final String workerName;
  final String labourType;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final dateStr = '${attendance.date.day}/${attendance.date.month}/${attendance.date.year}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.red.withValues(alpha: 0.2),
            child: const Icon(Icons.cancel, color: Colors.red),
          ),
          title: Text(workerName, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text('Absent', style: TextStyle(fontSize: 11, color: Colors.red.shade800)),
                backgroundColor: Colors.red.withValues(alpha: 0.2),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Text('$labourType • $dateStr', style: Get.textTheme.bodySmall),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
            tooltip: 'Edit attendance',
          ),
        ),
      ),
    );
  }
}

/// Edit Attendance dialog: change status Present/Absent; if Present show hours and overtime.
class _EditAttendanceDialog extends StatefulWidget {
  const _EditAttendanceDialog({
    required this.attendance,
    required this.workerName,
    required this.labourType,
    required this.onSave,
    required this.onCancel,
  });

  final AttendanceModel attendance;
  final String workerName;
  final String labourType;
  final void Function(AttendanceStatus newStatus, double hoursWorked, bool overtimeEnabled, double overtimeAmount) onSave;
  final VoidCallback onCancel;

  @override
  State<_EditAttendanceDialog> createState() => _EditAttendanceDialogState();
}

class _EditAttendanceDialogState extends State<_EditAttendanceDialog> {
  late AttendanceStatus _status;
  late double _hoursWorked;
  late bool _overtimeEnabled;
  final _overtimeAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.attendance.attendanceStatus ?? (widget.attendance.isPresent ? AttendanceStatus.present : AttendanceStatus.absent);
    _hoursWorked = widget.attendance.hoursWorked.clamp(AttendanceController.minHours, AttendanceController.maxHours);
    if (_hoursWorked < AttendanceController.minHours) _hoursWorked = 8;
    _overtimeEnabled = widget.attendance.overtimeEnabled;
    _overtimeAmountController.text = widget.attendance.overtimeAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _overtimeAmountController.dispose();
    super.dispose();
  }

  void _save() {
    double hours = _hoursWorked;
    bool otEnabled = _overtimeEnabled;
    double otAmount = 0;
    if (_status == AttendanceStatus.present) {
      hours = hours.clamp(AttendanceController.minHours, AttendanceController.maxHours);
      if (otEnabled) {
        otAmount = double.tryParse(_overtimeAmountController.text.trim()) ?? 0;
        if (otAmount < 0) otAmount = 0;
      }
    } else {
      hours = 0;
      otEnabled = false;
      otAmount = 0;
    }
    widget.onSave(_status, hours, otEnabled, otAmount);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${widget.attendance.date.day}/${widget.attendance.date.month}/${widget.attendance.date.year}';
    final isPresent = _status == AttendanceStatus.present;
    return AlertDialog(
      title: const Text('Edit Attendance'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.workerName, style: Get.textTheme.titleSmall),
            Text('${widget.labourType} • $dateStr', style: Get.textTheme.bodySmall),
            const SizedBox(height: 16),
            DropdownButtonFormField<AttendanceStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Attendance Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: AttendanceStatus.present, child: Text('Present')),
                DropdownMenuItem(value: AttendanceStatus.absent, child: Text('Absent')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            if (isPresent) ...[
              const SizedBox(height: 16),
              Text('Hours Worked (${AttendanceController.minHours}-${AttendanceController.maxHours})',
                  style: Get.textTheme.bodySmall),
              Slider(
                value: _hoursWorked,
                min: AttendanceController.minHours,
                max: AttendanceController.maxHours,
                divisions: 11,
                label: _hoursWorked.toStringAsFixed(0),
                onChanged: (v) => setState(() => _hoursWorked = v),
              ),
              Text('${_hoursWorked.toStringAsFixed(0)} hours', style: Get.textTheme.titleSmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Overtime', style: Get.textTheme.bodyMedium),
                  const SizedBox(width: 12),
                  Switch(
                    value: _overtimeEnabled,
                    onChanged: (v) => setState(() => _overtimeEnabled = v),
                  ),
                ],
              ),
              if (_overtimeEnabled) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _overtimeAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Overtime Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
