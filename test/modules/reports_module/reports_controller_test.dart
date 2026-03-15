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
import 'package:personal_construction_manager/modules/reports_module/controllers/reports_controller.dart';

LabourModel _worker(String id, {double? hourlyRate, double? fixedDayRate, String? name}) =>
    LabourModel(
      id: id,
      name: name ?? 'Worker $id',
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

AttendanceModel _att({
  required String workerId,
  bool present = true,
  double hours = 8,
  DateTime? date,
}) =>
    AttendanceModel(
      id: 'a$workerId',
      workerId: workerId,
      date: date ?? DateTime.now(),
      hoursWorked: hours,
      overtimeHours: 0,
      attendanceType: AttendanceType.fullDay,
      attendanceStatus: present ? AttendanceStatus.present : AttendanceStatus.absent,
    );

MaterialModel _material(String id, {double totalPrice = 100, String name = 'Cement'}) =>
    MaterialModel(
      id: id,
      category: MaterialCategory.cement,
      materialName: name,
      quantity: 1,
      unitType: MaterialUnit.bag,
      pricePerUnit: totalPrice,
      totalPrice: totalPrice,
    );

WorkerPaymentRecordModel _payment(String id, {required String workerId, double amountPaid = 500}) =>
    WorkerPaymentRecordModel(
      id: id,
      workerId: workerId,
      amountPaid: amountPaid,
      paymentDate: DateTime.now(),
    );

class FakeLabourRepo implements LabourRepositoryInterface {
  final List<LabourModel> list;
  FakeLabourRepo({required this.list});
  @override
  Stream<List<LabourModel>> streamLabour({
    int limit = 20,
    dynamic startAfter,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) =>
      Stream.value(list);
}

class FakeAttendanceRepo implements AttendanceRepositoryInterface {
  final List<AttendanceModel> todayList;
  final List<AttendanceModel> periodList;
  FakeAttendanceRepo({required this.todayList, required this.periodList});
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
  }) =>
      Stream.value(periodList);
}

class FakeMaterialRepo implements MaterialRepositoryInterface {
  final List<MaterialModel> list;
  FakeMaterialRepo({required this.list});
  @override
  Stream<List<MaterialModel>> streamMaterials({
    int limit = 20,
    dynamic startAfter,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) =>
      Stream.value(list);
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
  }) =>
      Stream.value(list);
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('ReportsController', () {
    group('filter date range', () {
      test('today returns same start and end', () {
        Get.put(
          ReportsController(
            labourRepo: FakeLabourRepo(list: []),
            attendanceRepo: FakeAttendanceRepo(todayList: [], periodList: []),
            materialRepo: FakeMaterialRepo(list: []),
            workerPaymentRepo: FakeWorkerPaymentRepo(list: []),
          ),
        );
        final c = Get.find<ReportsController>();
        c.filter.value = ReportsFilter.today;
        final (start, end) = c.filterDateRange;
        expect(start, end);
        Get.reset();
      });

      test('setFilter updates period stream', () {
        final c = ReportsController(
          labourRepo: FakeLabourRepo(list: []),
          attendanceRepo: FakeAttendanceRepo(todayList: [], periodList: []),
          materialRepo: FakeMaterialRepo(list: []),
          workerPaymentRepo: FakeWorkerPaymentRepo(list: []),
        );
        Get.put(c);
        c.setFilter(ReportsFilter.thisWeek);
        expect(c.filter.value, ReportsFilter.thisWeek);
        Get.reset();
      });
    });

    group('report calculations from streams', () {
      test('totalWorkers and attendance stats update when streams emit', () async {
        final workers = [_worker('w1'), _worker('w2'), _worker('w3')];
        final todayAtt = [
          _att(workerId: 'w1', present: true),
          _att(workerId: 'w2', present: true),
          _att(workerId: 'w3', present: false),
        ];
        final c = ReportsController(
          labourRepo: FakeLabourRepo(list: workers),
          attendanceRepo: FakeAttendanceRepo(
            todayList: todayAtt,
            periodList: todayAtt,
          ),
          materialRepo: FakeMaterialRepo(list: []),
          workerPaymentRepo: FakeWorkerPaymentRepo(list: []),
        );
        Get.put(c);
        c.refreshStreams();
        for (var i = 0; i < 10; i++) await Future<void>.delayed(Duration.zero);
        expect(c.totalWorkers.value, 3);
        expect(c.presentToday.value, 2);
        expect(c.absentToday.value, 1);
        Get.reset();
      });

      test('payment totals and material cost update from streams', () async {
        final materials = [
          _material('m1', totalPrice: 100),
          _material('m2', totalPrice: 200),
        ];
        final payments = [
          _payment('p1', workerId: 'w1', amountPaid: 300),
          _payment('p2', workerId: 'w2', amountPaid: 200),
        ];
        final c = ReportsController(
          labourRepo: FakeLabourRepo(list: []),
          attendanceRepo: FakeAttendanceRepo(todayList: [], periodList: []),
          materialRepo: FakeMaterialRepo(list: materials),
          workerPaymentRepo: FakeWorkerPaymentRepo(list: payments),
        );
        Get.put(c);
        c.refreshStreams();
        for (var i = 0; i < 10; i++) await Future<void>.delayed(Duration.zero);
        expect(c.totalMaterialCost.value, 300);
        expect(c.totalPaymentsMade.value, 500);
        Get.reset();
      });
    });

    group('search filter', () {
      test('filteredWorkers filters by name', () async {
        final workers = [
          _worker('1', name: 'Ramesh'),
          _worker('2', name: 'Suresh'),
          _worker('3', name: 'Raju'),
        ];
        final c = ReportsController(
          labourRepo: FakeLabourRepo(list: workers),
          attendanceRepo: FakeAttendanceRepo(todayList: [], periodList: []),
          materialRepo: FakeMaterialRepo(list: []),
          workerPaymentRepo: FakeWorkerPaymentRepo(list: []),
        );
        Get.put(c);
        c.refreshStreams();
        for (var i = 0; i < 10; i++) await Future<void>.delayed(Duration.zero);
        c.setSearch('Ram');
        expect(c.filteredWorkers.length, 1);
        expect(c.filteredWorkers.first.name, 'Ramesh');
        Get.reset();
      });

      test('filteredMaterials filters by name and amount', () async {
        final materials = [
          _material('1', name: 'Cement', totalPrice: 500),
          _material('2', name: 'Sand', totalPrice: 300),
        ];
        final c = ReportsController(
          labourRepo: FakeLabourRepo(list: []),
          attendanceRepo: FakeAttendanceRepo(todayList: [], periodList: []),
          materialRepo: FakeMaterialRepo(list: materials),
          workerPaymentRepo: FakeWorkerPaymentRepo(list: []),
        );
        Get.put(c);
        c.refreshStreams();
        for (var i = 0; i < 10; i++) await Future<void>.delayed(Duration.zero);
        c.setSearch('Cement');
        expect(c.filteredMaterials.length, 1);
        c.setSearch('500');
        expect(c.filteredMaterials.length, 1);
        Get.reset();
      });
    });
  });
}
