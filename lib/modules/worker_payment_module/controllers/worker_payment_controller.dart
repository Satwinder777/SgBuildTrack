import 'dart:async';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/payment_calculator.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/labour_model.dart';
import '../../../data/models/worker_payment_record_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/attendance_repository_interface.dart';
import '../../../data/repositories/labour_repository.dart';
import '../../../data/repositories/labour_repository_interface.dart';
import '../../../data/repositories/worker_payment_repository.dart';
import '../../../data/repositories/worker_payment_repository_interface.dart';
import '../../../core/utils/app_logger.dart';

class WorkerPaymentSummary {
  WorkerPaymentSummary({
    required this.worker,
    required this.totalEarnings,
    required this.totalPaid,
    required this.pending,
    required this.totalHours,
    required this.workingDays,
  });

  final LabourModel worker;
  final double totalEarnings;
  final double totalPaid;
  final double pending;
  final double totalHours;
  final int workingDays;
}

class WorkerPaymentController extends GetxController {
  WorkerPaymentController({
    LabourRepositoryInterface? labourRepo,
    AttendanceRepositoryInterface? attendanceRepo,
    WorkerPaymentRepositoryInterface? paymentRepo,
  })  : _labourRepo = labourRepo ?? LabourRepository(),
        _attendanceRepo = attendanceRepo ?? AttendanceRepository(),
        _paymentRepo = paymentRepo ?? WorkerPaymentRepository();

  final LabourRepositoryInterface _labourRepo;
  final AttendanceRepositoryInterface _attendanceRepo;
  final WorkerPaymentRepositoryInterface _paymentRepo;
  final _uuid = const Uuid();

  StreamSubscription? _labourSub;
  StreamSubscription? _attendanceSub;
  StreamSubscription? _paymentsSub;

  final workers = <LabourModel>[].obs;
  final attendanceList = <AttendanceModel>[].obs;
  final paymentRecords = <WorkerPaymentRecordModel>[].obs;
  final isLoading = true.obs;
  final saveError = Rxn<String>();

  /// Filter: from/to date for attendance-based earnings
  final fromDate = Rxn<DateTime>();
  final toDate = Rxn<DateTime>();

  @override
  void onReady() {
    _setDefaultDateRange();
    subscribeLabour();
    subscribeAttendance();
    subscribePayments();
    super.onReady();
  }

  @override
  void onClose() {
    _labourSub?.cancel();
    _attendanceSub?.cancel();
    _paymentsSub?.cancel();
    super.onClose();
  }

  void _setDefaultDateRange() {
    final now = DateTime.now();
    fromDate.value = DateTime(now.year, now.month - 1, now.day);
    toDate.value = now;
  }

  void subscribeLabour() {
    _labourSub?.cancel();
    _labourSub = _labourRepo
        .streamLabour(limit: AppConstants.defaultPageSize * 2)
        .listen((list) {
      workers.assignAll(list);
    }, onError: (e) {
      AppLogger.error('WorkerPayment: labour stream error', error: e);
    });
  }

  void subscribeAttendance() {
    _attendanceSub?.cancel();
    _attendanceSub = _attendanceRepo
        .streamAttendance(
          fromDate: fromDate.value,
          toDate: toDate.value,
          limit: 500,
        )
        .listen((list) {
      attendanceList.assignAll(list);
    }, onError: (e) {
      AppLogger.error('WorkerPayment: attendance stream error', error: e);
    });
  }

  void subscribePayments() {
    _paymentsSub?.cancel();
    _paymentsSub = _paymentRepo
        .streamWorkerPayments(limit: 500)
        .listen((list) {
      paymentRecords.assignAll(list);
    }, onError: (e) {
      AppLogger.error('WorkerPayment: payments stream error', error: e);
    });
  }

  /// Compute payment summary from reactive attendance and payment lists. Updates automatically when streams emit.
  WorkerPaymentSummary summaryForWorker(LabourModel worker) {
    return calculatePaymentSummary(
      worker: worker,
      attendanceRecords: attendanceList.where((a) => a.workerId == worker.id).toList(),
      payments: paymentRecords.where((p) => p.workerId == worker.id).toList(),
    );
  }

  /// Helper: compute totalEarnings, totalPaid, pending from attendance and payments. Used by summaryForWorker.
  static WorkerPaymentSummary calculatePaymentSummary({
    required LabourModel worker,
    required List<AttendanceModel> attendanceRecords,
    required List<WorkerPaymentRecordModel> payments,
  }) {
    final totalEarnings = PaymentCalculator.totalEarningsFromAttendance(
      attendances: attendanceRecords,
      worker: worker,
    );
    final totalPaid = payments.fold<double>(0, (s, p) => s + p.amountPaid);
    final pending = PaymentCalculator.pendingAmount(
      totalEarnings: totalEarnings,
      totalPaid: totalPaid,
    );
    final totalHours = attendanceRecords.fold<double>(0, (s, a) => s + a.totalHours);
    final workingDays = attendanceRecords.where((a) {
      switch (a.attendanceType) {
        case AttendanceType.fullDay:
        case AttendanceType.halfDay:
        case AttendanceType.present:
        case AttendanceType.overtime:
          return true;
        case AttendanceType.absent:
        case AttendanceType.leave:
          return false;
      }
    }).length;
    return WorkerPaymentSummary(
      worker: worker,
      totalEarnings: totalEarnings,
      totalPaid: totalPaid,
      pending: pending,
      totalHours: totalHours,
      workingDays: workingDays,
    );
  }

  /// Save payment to Firestore. Stream will emit; UI updates automatically. No manual refresh.
  Future<bool> payNow(LabourModel worker, double amount, String notes) async {
    saveError.value = null;
    if (amount <= 0) {
      saveError.value = 'Amount must be greater than 0';
      return false;
    }
    final summary = summaryForWorker(worker);
    if (amount > summary.pending) {
      saveError.value = 'Amount cannot exceed pending (${summary.pending.toStringAsFixed(0)})';
      return false;
    }
    final record = WorkerPaymentRecordModel(
      id: _uuid.v4(),
      workerId: worker.id,
      amountPaid: amount,
      paymentDate: DateTime.now(),
      paymentType: 'manual',
      notes: notes.isEmpty ? null : notes,
      createdAt: DateTime.now(),
    );
    try {
      await _paymentRepo.addWorkerPayment(record);
      final newPending = (summary.pending - amount).clamp(0.0, double.infinity);
      AppLogger.calc('Payment saved for worker: ${worker.id}');
      AppLogger.calc('Amount: $amount');
      AppLogger.calc('Updated pending amount: $newPending');
      return true;
    } catch (e, st) {
      AppLogger.error('Worker payment save failed', error: e, stackTrace: st);
      saveError.value = 'Failed to save: ${e.toString()}';
      return false;
    }
  }

  List<WorkerPaymentRecordModel> paymentHistoryForWorker(String workerId) {
    return paymentRecords.where((p) => p.workerId == workerId).toList();
  }
}
