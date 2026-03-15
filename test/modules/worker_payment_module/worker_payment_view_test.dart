import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:personal_construction_manager/data/models/labour_model.dart';
import 'package:personal_construction_manager/data/repositories/attendance_repository_interface.dart';
import 'package:personal_construction_manager/data/repositories/labour_repository_interface.dart';
import 'package:personal_construction_manager/data/repositories/worker_payment_repository_interface.dart';
import 'package:personal_construction_manager/data/models/attendance_model.dart';
import 'package:personal_construction_manager/data/models/worker_payment_record_model.dart';
import 'package:personal_construction_manager/modules/worker_payment_module/controllers/worker_payment_controller.dart';
import 'package:personal_construction_manager/modules/worker_payment_module/views/worker_payment_view.dart';

class FakeAttendanceRepo implements AttendanceRepositoryInterface {
  @override Future<void> addAttendance(AttendanceModel model) async {}
  @override Future<void> updateAttendance(AttendanceModel model) async {}
  @override Future<void> deleteAttendance(String id) async {}
  @override Future<AttendanceModel?> getByWorkerAndDate(String workerId, DateTime date) async => null;
  @override Stream<List<AttendanceModel>> streamAttendanceForDate(DateTime date) => Stream.value([]);
  @override Stream<List<AttendanceModel>> streamAttendance({
    String? workerId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) => Stream.value([]);
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
  @override Future<void> addWorkerPayment(WorkerPaymentRecordModel model) async {}
  @override Stream<List<WorkerPaymentRecordModel>> streamWorkerPayments({
    String? workerId,
    int limit = 100,
  }) =>
      Stream.value([]);
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(WorkerPaymentController(
      labourRepo: FakeLabourRepo(),
      attendanceRepo: FakeAttendanceRepo(),
      paymentRepo: FakeWorkerPaymentRepo(),
    ));
  });

  tearDown(() => Get.reset());

  group('WorkerPaymentView', () {
    testWidgets('shows Worker Payments app bar', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const WorkerPaymentView(),
        ),
      );
      await tester.pump();
      expect(find.text('Worker Payments'), findsOneWidget);
    });

    testWidgets('shows empty message when no workers', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const WorkerPaymentView(),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Add workers'), findsOneWidget);
    });
  });
}
