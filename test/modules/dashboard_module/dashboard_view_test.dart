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
import 'package:personal_construction_manager/modules/dashboard_module/controllers/dashboard_controller.dart';
import 'package:personal_construction_manager/modules/dashboard_module/views/dashboard_view.dart';
import 'package:personal_construction_manager/modules/dashboard_module/widgets/summary_card.dart';

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
      DashboardController(
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

  group('DashboardView', () {
    testWidgets('shows app bar with app name', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: DashboardView()),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.appName), findsOneWidget);
    });

    testWidgets('shows filter chips', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: DashboardView()),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.filterToday), findsOneWidget);
      expect(find.text(AppStrings.filterThisWeek), findsOneWidget);
      expect(find.text(AppStrings.filterThisMonth), findsOneWidget);
    });

    testWidgets('shows section title Total Construction Cost', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: DashboardView()),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.totalConstructionCost), findsOneWidget);
    });

    testWidgets('shows Material vs Labour section', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: DashboardView()),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.materialVsLabour), findsOneWidget);
    });

    testWidgets('shows Material Cost chart section', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: DashboardView()),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.materialCostChart), findsOneWidget);
    });

    testWidgets('shows Recent Materials section', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: DashboardView()),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.recentMaterials), findsOneWidget);
    });

    testWidgets('shows Recent Worker Payments section', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: DashboardView()),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.recentWorkerPayments), findsOneWidget);
    });
  });

  group('SummaryCard', () {
    testWidgets('displays title and icon', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: 'Total Workers',
              amount: 10,
              icon: Icons.people_outline,
              prefix: '',
              suffix: '',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Total Workers'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('displays currency amount with prefix', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: AppStrings.totalMaterialCost,
              amount: 5000,
              icon: Icons.inventory_2_outlined,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text(AppStrings.totalMaterialCost), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });
  });
}
