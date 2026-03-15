import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/labour_model.dart';
import '../../../data/repositories/labour_repository.dart';

class LabourFormController extends GetxController {
  LabourFormController({LabourRepository? repository})
      : _repo = repository ?? LabourRepository();

  final LabourRepository _repo;
  final _uuid = const Uuid();
  final formKey = GlobalKey<FormState>();

  final id = ''.obs;
  final name = ''.obs;
  final phone = ''.obs;
  final address = ''.obs;
  final labourType = LabourType.helper.obs;
  final paymentMode = LabourPaymentMode.hourly.obs;
  final hourlyRate = 0.0.obs;
  final fixedDayRate = 0.0.obs;
  final workHours = 0.0.obs;
  final totalPayment = 0.0.obs;
  final date = Rxn<DateTime>();
  final notes = ''.obs;
  final isSaving = false.obs;
  DateTime? _initialCreatedAt;

  bool get isEdit => id.value.isNotEmpty;

  @override
  void onInit() {
    final arg = Get.arguments as LabourModel?;
    if (arg != null) {
      id.value = arg.id;
      name.value = arg.name;
      phone.value = arg.phone ?? '';
      address.value = arg.address ?? '';
      labourType.value = arg.labourType;
      paymentMode.value = arg.paymentMode;
      hourlyRate.value = arg.hourlyRate ?? 0;
      fixedDayRate.value = arg.fixedDayRate ?? 0;
      workHours.value = arg.workHours ?? 0;
      totalPayment.value = arg.totalPayment;
      date.value = arg.date ?? DateTime.now();
      notes.value = arg.notes ?? '';
      _initialCreatedAt = arg.createdAt;
    } else {

      date.value = DateTime.now();
    }
    super.onInit();
  }

  void setLabourType(LabourType t) => labourType.value = t;
  void setPaymentMode(LabourPaymentMode m) {
    paymentMode.value = m;
    recalculateTotal();
  }
  void setName(String v) => name.value = v;
  void setPhone(String v) => phone.value = v;
  void setAddress(String v) => address.value = v;
  void setHourlyRate(double v) {
    hourlyRate.value = v;
    recalculateTotal();
  }
  void setFixedDayRate(double v) {
    fixedDayRate.value = v;
    recalculateTotal();
  }
  void setWorkHours(double v) {
    workHours.value = v;
    recalculateTotal();
  }
  void setDate(DateTime? d) => date.value = d;
  void setNotes(String v) => notes.value = v;

  void recalculateTotal() {
    if (paymentMode.value == LabourPaymentMode.hourly) {
      totalPayment.value = workHours.value * hourlyRate.value;
    } else {
      totalPayment.value = fixedDayRate.value;
    }
  }

  Future<bool> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return false;
    if (name.value.trim().isEmpty) {
      Get.snackbar('Error', 'Name is required');
      return false;
    }
    isSaving.value = true;
    try {
      final now = DateTime.now();
      final model = LabourModel(
        id:  _uuid.v4(),
        name: name.value.trim(),
        phone: phone.value.isEmpty ? null : phone.value,
        address: address.value.isEmpty ? null : address.value,
        labourType: labourType.value,
        hourlyRate: hourlyRate.value > 0 ? hourlyRate.value : null,
        fixedDayRate: fixedDayRate.value > 0 ? fixedDayRate.value : null,
        workHours: workHours.value > 0 ? workHours.value : null,
        paymentMode: paymentMode.value,
        totalPayment: totalPayment.value,
        date: date.value ?? now,
        notes: notes.value.isEmpty ? null : notes.value,
        createdAt: isEdit ? (_initialCreatedAt ?? now) : now,
        updatedAt: now,
      );
      if (isEdit) {
        await _repo.updateLabour(model);
        AppLogger.form('Labour updated', data: {'id': id.value});
      } else {
        await _repo.addLabour(model);
        AppLogger.form('Labour added', data: {'id': id.value});
      }
      Get.back(result: true);
      return true;
    } catch (e, st) {
      AppLogger.error('Labour save failed', error: e, stackTrace: st);
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
