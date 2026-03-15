import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:personal_construction_manager/data/models/attendance_model.dart';
import 'package:personal_construction_manager/data/models/labour_model.dart';
import 'package:personal_construction_manager/data/models/material_model.dart';
import 'package:personal_construction_manager/data/models/worker_payment_record_model.dart';
import 'package:personal_construction_manager/data/repositories/attendance_repository_interface.dart';
import 'package:personal_construction_manager/data/repositories/labour_repository_interface.dart';
import 'package:personal_construction_manager/data/repositories/material_repository_interface.dart';
import 'package:personal_construction_manager/data/repositories/worker_payment_repository_interface.dart';
import 'package:personal_construction_manager/modules/dashboard_module/controllers/dashboard_controller.dart';

class FakeLabourRepo implements LabourRepositoryInterface {
  final List<LabourModel> list;
  FakeLabourRepo({required this.list});
  @override
  Stream<List<LabourModel>> streamLabour({
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) => Stream.value(list);
}

class FakeAttendanceRepo implements AttendanceRepositoryInterface {
  final List<AttendanceModel> todayList;
  final List<AttendanceModel> allList;
  FakeAttendanceRepo({required this.todayList, required this.allList});
  @override
  Future<void> addAttendance(AttendanceModel model) async {}
  @override
  Future<void> updateAttendance(AttendanceModel model) async {}
  @override
  Future<void> deleteAttendance(String id) async {}
  @override
  Future<AttendanceModel?> getByWorkerAndDate(String workerId, DateTime date) async => null;
  @override
  Stream<List<AttendanceModel>> streamAttendanceForDate(DateTime date) => Stream.value(todayList);
  @override
  Stream<List<AttendanceModel>> streamAttendance({
    String? workerId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) => Stream.value(allList);
}

class FakeMaterialRepo implements MaterialRepositoryInterface {
  final List<MaterialModel> list;
  FakeMaterialRepo({required this.list});
  @override
  Stream<List<MaterialModel>> streamMaterials({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) => Stream.value(list);
}

class FakeWorkerPaymentRepo implements WorkerPaymentRepositoryInterface {
  final List<WorkerPaymentRecordModel> list;
  FakeWorkerPaymentRepo({required this.list});
  @override
  Future<void> addWorkerPayment(WorkerPaymentRecordModel model) async {}
  @override
  Stream<List<WorkerPaymentRecordModel>> streamWorkerPayments({
    String? workerId,
    int limit = 100,
  }) => Stream.value(list);
}

LabourModel _worker(String id, {double? hourlyRate, double? fixedDayRate}) =>
    LabourModel(
      id: id,
      name: 'W$id',
      labourType: LabourType.helper,
      paymentMode: hourlyRate != null ? LabourPaymentMode.hourly : LabourPaymentMode.fixed,
      hourlyRate: hourlyRate,
      fixedDayRate: fixedDayRate,
      totalPayment: 0,
      date: null,
      notes: null,
      createdAt: null,
      updatedAt: null,
    );

AttendanceModel _att(String workerId, {double hours = 8, bool present = true}) =>
    AttendanceModel(
      id: 'a$workerId',
      workerId: workerId,
      date: DateTime.now(),
      hoursWorked: hours,
      overtimeHours: 0,
      attendanceType: AttendanceType.fullDay,
      attendanceStatus: present ? AttendanceStatus.present : AttendanceStatus.absent,
    );

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('DashboardController', () {
    test('recomputes stats when streams emit', () async {
      final workers = [_worker('w1', hourlyRate: 100), _worker('w2', fixedDayRate: 800)];
      final todayAtt = [_att('w1', hours: 8), _att('w2', present: true)];
      final allAtt = todayAtt;
      final materials = [
        MaterialModel(
          id: 'm1',
          category: MaterialCategory.cement,
          materialName: 'C',
          quantity: 2,
          unitType: MaterialUnit.bag,
          pricePerUnit: 50,
          totalPrice: 100,
        ),
      ];
      final workerPayments = [
        WorkerPaymentRecordModel(
          id: 'p1',
          workerId: 'w1',
          amountPaid: 500,
          paymentDate: DateTime.now(),
        ),
      ];

      final controller = DashboardController(
        labourRepo: FakeLabourRepo(list: workers),
        attendanceRepo: FakeAttendanceRepo(todayList: todayAtt, allList: allAtt),
        materialRepo: FakeMaterialRepo(list: materials),
        workerPaymentRepo: FakeWorkerPaymentRepo(list: workerPayments),
      );
      Get.put(controller);
      controller.onReady();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(controller.totalWorkers.value, 2);
      expect(controller.presentToday.value, 2);
      expect(controller.totalHoursToday.value, 16);
      expect(controller.todayLabourCost.value, 800 + 800);
      expect(controller.totalMaterialCost.value, 100);
      expect(controller.totalPaymentsMade.value, 500);
      expect(controller.pendingPayments.value, greaterThanOrEqualTo(0));
      expect(controller.isLoading.value, false);
    });

    test('filter defaults to today and can be set', () {
      final controller = DashboardController(
        labourRepo: FakeLabourRepo(list: []),
        attendanceRepo: FakeAttendanceRepo(todayList: [], allList: []),
        materialRepo: FakeMaterialRepo(list: []),
        workerPaymentRepo: FakeWorkerPaymentRepo(list: []),
      );
      Get.put(controller);
      expect(controller.filter.value, DashboardFilter.today);
      controller.setFilter(DashboardFilter.thisWeek);
      expect(controller.filter.value, DashboardFilter.thisWeek);
    });

    test('refreshStreams can be called without error', () async {
      final controller = DashboardController(
        labourRepo: FakeLabourRepo(list: []),
        attendanceRepo: FakeAttendanceRepo(todayList: [], allList: []),
        materialRepo: FakeMaterialRepo(list: []),
        workerPaymentRepo: FakeWorkerPaymentRepo(list: []),
      );
      Get.put(controller);
      controller.refreshStreams();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(controller.totalWorkers.value, 0);
    });
  });
}
