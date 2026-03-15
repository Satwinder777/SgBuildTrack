import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:personal_construction_manager/core/constants/app_strings.dart';
import 'package:personal_construction_manager/data/models/attendance_model.dart';
import 'package:personal_construction_manager/data/models/labour_model.dart';
import 'package:personal_construction_manager/data/models/material_model.dart';
import 'package:personal_construction_manager/data/models/worker_payment_record_model.dart';
import 'package:personal_construction_manager/data/repositories/attendance_repository_interface.dart';
import 'package:personal_construction_manager/data/repositories/labour_repository_interface.dart';
import 'package:personal_construction_manager/data/repositories/material_repository_interface.dart';
import 'package:personal_construction_manager/data/repositories/worker_payment_repository_interface.dart';
import 'package:personal_construction_manager/modules/reports_module/controllers/reports_controller.dart';
import 'package:personal_construction_manager/modules/reports_module/views/reports_view.dart';

class FakeLabourRepo implements LabourRepositoryInterface {
  @override
  Stream<List<LabourModel>> streamLabour({
    int limit = 20,
    dynamic startAfter,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) =>
      Stream.value([]);
}

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

class FakeMaterialRepo implements MaterialRepositoryInterface {
  @override
  Stream<List<MaterialModel>> streamMaterials({
    int limit = 20,
    dynamic startAfter,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) =>
      Stream.value([]);
}

class FakeWorkerPaymentRepo implements WorkerPaymentRepositoryInterface {
  @override
  Future<void> addWorkerPayment(WorkerPaymentRecordModel model) async {}
  @override
  Stream<List<WorkerPaymentRecordModel>> streamWorkerPayments({
    String? workerId,
    int limit = 100,
  }) =>
      Stream.value([]);
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(
      ReportsController(
        labourRepo: FakeLabourRepo(),
        attendanceRepo: FakeAttendanceRepo(),
        materialRepo: FakeMaterialRepo(),
        workerPaymentRepo: FakeWorkerPaymentRepo(),
      ),
    );
  });

  tearDown(() {
    Get.reset();
  });

  group('ReportsView', () {
    Future<void> pumpAndLoad(WidgetTester tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: ReportsView()),
      );
      await tester.pumpAndSettle();
      // Allow stream emissions and loading to complete
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('shows app bar with Reports title', (tester) async {
      await pumpAndLoad(tester);
      expect(find.text(AppStrings.reports), findsOneWidget);
    });

    testWidgets('shows filter chips Today, This Week, This Month, Custom Range', (tester) async {
      await pumpAndLoad(tester);
      expect(find.text(AppStrings.filterToday), findsOneWidget);
      expect(find.text(AppStrings.filterThisWeek), findsOneWidget);
      expect(find.text(AppStrings.filterThisMonth), findsOneWidget);
      expect(find.text(AppStrings.filterCustomRange), findsOneWidget);
    });

    testWidgets('shows Overview section', (tester) async {
      await pumpAndLoad(tester);
      expect(find.text(AppStrings.reportsOverview), findsOneWidget);
    });

    testWidgets('shows search field with hint', (tester) async {
      await pumpAndLoad(tester);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows summary cards for Total Workers and Total Material Cost', (tester) async {
      await pumpAndLoad(tester);
      expect(find.text(AppStrings.totalWorkers), findsOneWidget);
      expect(find.text(AppStrings.totalMaterialCost), findsOneWidget);
    });
  });
}
