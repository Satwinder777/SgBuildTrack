import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:personal_construction_manager/data/models/attendance_model.dart';
import 'package:personal_construction_manager/data/models/labour_model.dart';
import 'package:personal_construction_manager/data/models/worker_payment_record_model.dart';
import 'package:personal_construction_manager/data/repositories/attendance_repository_interface.dart';
import 'package:personal_construction_manager/data/repositories/labour_repository_interface.dart';
import 'package:personal_construction_manager/data/repositories/worker_payment_repository_interface.dart';
import 'package:personal_construction_manager/modules/worker_payment_module/controllers/worker_payment_controller.dart';

class FakeAttendanceRepo implements AttendanceRepositoryInterface {
  @override
  Future<void> addAttendance(AttendanceModel model) async {}
  @override
  Future<void> updateAttendance(AttendanceModel model) async {}
  @override
  Future<void> deleteAttendance(String id) async {}
  @override
  Future<AttendanceModel?> getByWorkerAndDate(String workerId, DateTime date) async => null;
  @override
  Stream<List<AttendanceModel>> streamAttendanceForDate(DateTime date) => Stream.value([]);
  @override
  Stream<List<AttendanceModel>> streamAttendance({
    String? workerId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) =>
      Stream.value([]);
}

class FakeLabourRepo implements LabourRepositoryInterface {
  @override
  Stream<List<LabourModel>> streamLabour({
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) =>
      Stream.value([]);
}

class FakeWorkerPaymentRepo implements WorkerPaymentRepositoryInterface {
  final List<WorkerPaymentRecordModel> _payments = [];
  final _controller = StreamController<List<WorkerPaymentRecordModel>>.broadcast();

  FakeWorkerPaymentRepo() {
    _controller.add([]);
  }

  @override
  Future<void> addWorkerPayment(WorkerPaymentRecordModel model) async {
    _payments.add(model);
    _controller.add(List.from(_payments));
  }

  @override
  Stream<List<WorkerPaymentRecordModel>> streamWorkerPayments({
    String? workerId,
    int limit = 100,
  }) =>
      _controller.stream;

  void dispose() => _controller.close();
}

void main() {
  late WorkerPaymentController controller;
  late FakeWorkerPaymentRepo fakePaymentRepo;

  setUp(() {
    Get.testMode = true;
    fakePaymentRepo = FakeWorkerPaymentRepo();
    controller = WorkerPaymentController(
      labourRepo: FakeLabourRepo(),
      attendanceRepo: FakeAttendanceRepo(),
      paymentRepo: fakePaymentRepo,
    );
  });

  tearDown(() {
    fakePaymentRepo.dispose();
    Get.reset();
  });

  group('WorkerPaymentController.calculatePaymentSummary', () {
    test('no payments -> totalPaid 0, pending equals totalEarnings', () {
      final worker = LabourModel(
        id: 'w1',
        name: 'Test',
        labourType: LabourType.helper,
        paymentMode: LabourPaymentMode.hourly,
        hourlyRate: 100,
        totalPayment: 0,
        date: null,
        notes: null,
        createdAt: null,
        updatedAt: null,
      );
      final attendance = [
        AttendanceModel(
          id: 'a1',
          workerId: 'w1',
          date: DateTime.now(),
          hoursWorked: 8,
          attendanceType: AttendanceType.present,
          attendanceStatus: AttendanceStatus.present,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final summary = WorkerPaymentController.calculatePaymentSummary(
        worker: worker,
        attendanceRecords: attendance,
        payments: [],
      );
      expect(summary.totalPaid, 0);
      expect(summary.totalEarnings, 800);
      expect(summary.pending, 800);
    });

    test('one payment -> totalPaid and pending update correctly', () {
      final worker = LabourModel(
        id: 'w1',
        name: 'Test',
        labourType: LabourType.helper,
        paymentMode: LabourPaymentMode.hourly,
        hourlyRate: 100,
        totalPayment: 0,
        date: null,
        notes: null,
        createdAt: null,
        updatedAt: null,
      );
      final attendance = [
        AttendanceModel(
          id: 'a1',
          workerId: 'w1',
          date: DateTime.now(),
          hoursWorked: 8,
          attendanceType: AttendanceType.present,
          attendanceStatus: AttendanceStatus.present,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final payments = [
        WorkerPaymentRecordModel(
          id: 'p1',
          workerId: 'w1',
          amountPaid: 300,
          paymentDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];
      final summary = WorkerPaymentController.calculatePaymentSummary(
        worker: worker,
        attendanceRecords: attendance,
        payments: payments,
      );
      expect(summary.totalPaid, 300);
      expect(summary.pending, 500);
    });

    test('multiple payments -> totalPaid is sum', () {
      final worker = LabourModel(
        id: 'w1',
        name: 'Test',
        labourType: LabourType.helper,
        paymentMode: LabourPaymentMode.hourly,
        hourlyRate: 50,
        totalPayment: 0,
        date: null,
        notes: null,
        createdAt: null,
        updatedAt: null,
      );
      final attendance = [
        AttendanceModel(
          id: 'a1',
          workerId: 'w1',
          date: DateTime.now(),
          hoursWorked: 8,
          attendanceType: AttendanceType.present,
          attendanceStatus: AttendanceStatus.present,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final payments = [
        WorkerPaymentRecordModel(
          id: 'p1',
          workerId: 'w1',
          amountPaid: 100,
          paymentDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        WorkerPaymentRecordModel(
          id: 'p2',
          workerId: 'w1',
          amountPaid: 200,
          paymentDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];
      final summary = WorkerPaymentController.calculatePaymentSummary(
        worker: worker,
        attendanceRecords: attendance,
        payments: payments,
      );
      expect(summary.totalPaid, 300);
      expect(summary.totalEarnings, 400);
      expect(summary.pending, 100);
    });
  });

  group('payNow validation', () {
    test('amount <= 0 returns false', () async {
      controller.workers.add(LabourModel(
        id: 'w1',
        name: 'A',
        labourType: LabourType.helper,
        paymentMode: LabourPaymentMode.hourly,
        hourlyRate: 100,
        totalPayment: 0,
        date: null,
        notes: null,
        createdAt: null,
        updatedAt: null,
      ));
      controller.attendanceList.add(AttendanceModel(
        id: 'a1',
        workerId: 'w1',
        date: DateTime.now(),
        hoursWorked: 8,
        attendanceType: AttendanceType.present,
        attendanceStatus: AttendanceStatus.present,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      final worker = controller.workers.first;
      final result = await controller.payNow(worker, 0, '');
      expect(result, false);
      expect(controller.saveError.value, isNotNull);
    });

    test('amount > pending returns false', () async {
      controller.workers.add(LabourModel(
        id: 'w1',
        name: 'A',
        labourType: LabourType.helper,
        paymentMode: LabourPaymentMode.hourly,
        hourlyRate: 100,
        totalPayment: 0,
        date: null,
        notes: null,
        createdAt: null,
        updatedAt: null,
      ));
      controller.attendanceList.add(AttendanceModel(
        id: 'a1',
        workerId: 'w1',
        date: DateTime.now(),
        hoursWorked: 8,
        attendanceType: AttendanceType.present,
        attendanceStatus: AttendanceStatus.present,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      final worker = controller.workers.first;
      final summary = controller.summaryForWorker(worker);
      final result = await controller.payNow(worker, summary.pending + 1, '');
      expect(result, false);
      expect(controller.saveError.value, isNotNull);
    });

    test('valid payment succeeds and stream updates', () async {
      controller.workers.add(LabourModel(
        id: 'w1',
        name: 'A',
        labourType: LabourType.helper,
        paymentMode: LabourPaymentMode.hourly,
        hourlyRate: 100,
        totalPayment: 0,
        date: null,
        notes: null,
        createdAt: null,
        updatedAt: null,
      ));
      controller.attendanceList.add(AttendanceModel(
        id: 'a1',
        workerId: 'w1',
        date: DateTime.now(),
        hoursWorked: 8,
        attendanceType: AttendanceType.present,
        attendanceStatus: AttendanceStatus.present,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      final worker = controller.workers.first;
      final result = await controller.payNow(worker, 200, 'test');
      expect(result, true);
      expect(controller.saveError.value, isNull);
    });
  });
}
