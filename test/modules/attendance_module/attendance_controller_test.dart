import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:personal_construction_manager/data/models/attendance_model.dart';
import 'package:personal_construction_manager/data/models/labour_model.dart';
import 'package:personal_construction_manager/data/repositories/attendance_repository_interface.dart';
import 'package:personal_construction_manager/data/repositories/labour_repository_interface.dart';
import 'package:personal_construction_manager/modules/attendance_module/controllers/attendance_controller.dart';

/// Fake repo for tests: no Firebase. get returns null, add completes, streams emit empty.
class FakeAttendanceRepository implements AttendanceRepositoryInterface {
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

/// Fake labour repo: stream emits empty list; no Firebase.
class FakeLabourRepository implements LabourRepositoryInterface {
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

void main() {
  late AttendanceController controller;

  setUp(() {
    Get.testMode = true;
    controller = AttendanceController(
      attendanceRepo: FakeAttendanceRepository(),
      labourRepo: FakeLabourRepository(),
    );
  });

  tearDown(() {
    Get.reset();
  });

  group('AttendanceController', () {
    test('minHours and maxHours are 1 and 12', () {
      expect(AttendanceController.minHours, 1);
      expect(AttendanceController.maxHours, 12);
    });

    group('markPresent validation', () {
      test('hours out of range returns false', () async {
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
        controller.workers.add(worker);
        controller.selectedDate.value = DateTime(2025, 3, 14);
        final result = await controller.markPresent(worker, hoursWorked: 0, overtimeEnabled: false);
        expect(result, false);
        expect(controller.saveError.value, isNotNull);
      });

      test('negative overtime amount returns false', () async {
        final worker = LabourModel(
          id: 'w2',
          name: 'Test2',
          labourType: LabourType.mason,
          paymentMode: LabourPaymentMode.fixed,
          fixedDayRate: 800,
          totalPayment: 0,
          date: null,
          notes: null,
          createdAt: null,
          updatedAt: null,
        );
        controller.workers.add(worker);
        controller.selectedDate.value = DateTime(2025, 3, 14);
        final result = await controller.markPresent(
          worker,
          hoursWorked: 8,
          overtimeEnabled: true,
          overtimeAmount: -100,
        );
        expect(result, false);
      });

      test('valid markPresent succeeds', () async {
        final worker = LabourModel(
          id: 'w3',
          name: 'Valid',
          labourType: LabourType.helper,
          paymentMode: LabourPaymentMode.hourly,
          hourlyRate: 100,
          totalPayment: 0,
          date: null,
          notes: null,
          createdAt: null,
          updatedAt: null,
        );
        controller.workers.add(worker);
        controller.selectedDate.value = DateTime(2025, 3, 14);
        final result = await controller.markPresent(worker, hoursWorked: 8, overtimeEnabled: false);
        expect(result, true);
      });
    });

    group('markAbsent', () {
      test('markAbsent succeeds', () async {
        final worker = LabourModel(
          id: 'w4',
          name: 'Absent',
          labourType: LabourType.helper,
          paymentMode: LabourPaymentMode.hourly,
          hourlyRate: 50,
          totalPayment: 0,
          date: null,
          notes: null,
          createdAt: null,
          updatedAt: null,
        );
        controller.workers.add(worker);
        controller.selectedDate.value = DateTime(2025, 3, 14);
        final result = await controller.markAbsent(worker);
        expect(result, true);
      });
    });

    group('pendingWorkers', () {
      test('excludes workers who have attendance for date', () {
        final w1 = LabourModel(
          id: 'w1',
          name: 'Alice',
          labourType: LabourType.helper,
          paymentMode: LabourPaymentMode.hourly,
          hourlyRate: 50,
          totalPayment: 0,
          date: null,
          notes: null,
          createdAt: null,
          updatedAt: null,
        );
        final w2 = LabourModel(
          id: 'w2',
          name: 'Bob',
          labourType: LabourType.mason,
          paymentMode: LabourPaymentMode.fixed,
          fixedDayRate: 800,
          totalPayment: 0,
          date: null,
          notes: null,
          createdAt: null,
          updatedAt: null,
        );
        controller.workers.addAll([w1, w2]);
        controller.attendanceForDate.add(
          AttendanceModel(
            id: 'a1',
            workerId: 'w1',
            date: DateTime(2025, 3, 14),
            hoursWorked: 8,
            attendanceType: AttendanceType.present,
            attendanceStatus: AttendanceStatus.present,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final pending = controller.pendingWorkers;
        expect(pending.length, 1);
        expect(pending.first.id, 'w2');
      });

      test('search filters by name', () {
        controller.workers.addAll([
          LabourModel(
            id: '1',
            name: 'Ramesh',
            labourType: LabourType.helper,
            paymentMode: LabourPaymentMode.hourly,
            hourlyRate: 50,
            totalPayment: 0,
            date: null,
            notes: null,
            createdAt: null,
            updatedAt: null,
          ),
          LabourModel(
            id: '2',
            name: 'Suresh',
            labourType: LabourType.mason,
            paymentMode: LabourPaymentMode.fixed,
            fixedDayRate: 800,
            totalPayment: 0,
            date: null,
            notes: null,
            createdAt: null,
            updatedAt: null,
          ),
        ]);
        controller.attendanceForDate.clear();
        controller.setSearchQuery('Ram');
        final pending = controller.pendingWorkers;
        expect(pending.length, 1);
        expect(pending.first.name, 'Ramesh');
      });
    });

    group('overtime validation', () {
      test('hours 1-12 are valid range', () {
        expect(AttendanceController.minHours, 1);
        expect(AttendanceController.maxHours, 12);
      });
    });

    group('updateAttendanceRecord (edit/correct)', () {
      test('change Absent → Present succeeds', () async {
        final absent = AttendanceModel(
          id: 'att-1',
          workerId: 'w1',
          date: DateTime(2025, 3, 14),
          hoursWorked: 0,
          attendanceType: AttendanceType.absent,
          attendanceStatus: AttendanceStatus.absent,
          overtimeEnabled: false,
          overtimeAmount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        controller.workers.add(LabourModel(
          id: 'w1',
          name: 'Alice',
          labourType: LabourType.helper,
          paymentMode: LabourPaymentMode.hourly,
          hourlyRate: 50,
          totalPayment: 0,
          date: null,
          notes: null,
          createdAt: null,
          updatedAt: null,
        ));
        final result = await controller.updateAttendanceRecord(
          absent,
          newStatus: AttendanceStatus.present,
          hoursWorked: 8,
          overtimeEnabled: false,
        );
        expect(result, true);
      });

      test('change Present → Absent succeeds', () async {
        final present = AttendanceModel(
          id: 'att-2',
          workerId: 'w2',
          date: DateTime(2025, 3, 14),
          hoursWorked: 8,
          attendanceType: AttendanceType.present,
          attendanceStatus: AttendanceStatus.present,
          overtimeEnabled: false,
          overtimeAmount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final result = await controller.updateAttendanceRecord(
          present,
          newStatus: AttendanceStatus.absent,
        );
        expect(result, true);
      });

      test('edit hours worked for present record', () async {
        final present = AttendanceModel(
          id: 'att-3',
          workerId: 'w3',
          date: DateTime(2025, 3, 14),
          hoursWorked: 8,
          attendanceType: AttendanceType.present,
          attendanceStatus: AttendanceStatus.present,
          overtimeEnabled: false,
          overtimeAmount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final result = await controller.updateAttendanceRecord(
          present,
          newStatus: AttendanceStatus.present,
          hoursWorked: 6,
          overtimeEnabled: false,
        );
        expect(result, true);
      });

      test('edit overtime amount for present record', () async {
        final present = AttendanceModel(
          id: 'att-4',
          workerId: 'w4',
          date: DateTime(2025, 3, 14),
          hoursWorked: 8,
          attendanceType: AttendanceType.overtime,
          attendanceStatus: AttendanceStatus.present,
          overtimeEnabled: true,
          overtimeAmount: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final result = await controller.updateAttendanceRecord(
          present,
          newStatus: AttendanceStatus.present,
          hoursWorked: 8,
          overtimeEnabled: true,
          overtimeAmount: 100,
        );
        expect(result, true);
      });

      test('invalid record (empty id) returns false', () async {
        final invalid = AttendanceModel(
          id: '',
          workerId: 'w1',
          date: DateTime(2025, 3, 14),
          hoursWorked: 8,
          attendanceType: AttendanceType.present,
          attendanceStatus: AttendanceStatus.present,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final result = await controller.updateAttendanceRecord(
          invalid,
          newStatus: AttendanceStatus.present,
          hoursWorked: 8,
        );
        expect(result, false);
        expect(controller.saveError.value, isNotNull);
      });

      test('present with hours out of range returns false', () async {
        final present = AttendanceModel(
          id: 'att-5',
          workerId: 'w5',
          date: DateTime(2025, 3, 14),
          hoursWorked: 8,
          attendanceType: AttendanceType.present,
          attendanceStatus: AttendanceStatus.present,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final result = await controller.updateAttendanceRecord(
          present,
          newStatus: AttendanceStatus.present,
          hoursWorked: 0,
        );
        expect(result, false);
      });
    });
  });
}
