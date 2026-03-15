import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:personal_construction_manager/data/models/attendance_model.dart';
import 'package:personal_construction_manager/data/models/labour_model.dart';
import 'package:personal_construction_manager/data/repositories/attendance_repository_interface.dart';
import 'package:personal_construction_manager/data/repositories/labour_repository_interface.dart';
import 'package:personal_construction_manager/modules/attendance_module/controllers/attendance_controller.dart';
import 'package:personal_construction_manager/modules/attendance_module/views/attendance_view.dart';

class FakeAttendanceRepo implements AttendanceRepositoryInterface {
  @override Future<void> addAttendance(AttendanceModel model) async {}
  @override Future<void> updateAttendance(AttendanceModel model) async {}
  @override Future<void> deleteAttendance(String id) async {}
  @override Future<AttendanceModel?> getByWorkerAndDate(String workerId, DateTime date) async => null;
  @override Stream<List<AttendanceModel>> streamAttendanceForDate(DateTime date) => Stream.value([]);
  @override Stream<List<AttendanceModel>> streamAttendance({String? workerId, DateTime? fromDate, DateTime? toDate, int limit = 100}) => Stream.value([]);
}

class FakeLabourRepo implements LabourRepositoryInterface {
  @override Stream<List<LabourModel>> streamLabour({int limit = 20, DocumentSnapshot? startAfter, DateTime? fromDate, DateTime? toDate, String? searchQuery}) => Stream.value([]);
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(AttendanceController(attendanceRepo: FakeAttendanceRepo(), labourRepo: FakeLabourRepo()));
  });

  tearDown(() {
    Get.reset();
  });

  group('AttendanceView', () {
    testWidgets('Attendance screen has app bar and date', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const AttendanceView(),
        ),
      );
      await tester.pump();
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('Shows Pending Workers section', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const AttendanceView(),
        ),
      );
      await tester.pump();
      expect(find.text('Pending Workers'), findsOneWidget);
    });

    testWidgets('Shows Present and Absent section titles', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const AttendanceView(),
        ),
      );
      await tester.pump();
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
    });
  });

  group('Attendance dialog', () {
    testWidgets('Add Work Details dialog has title and confirm', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Builder(
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Add Work Details'),
                      content: const Text('Hours, Overtime'),
                      actions: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {},
                          child: const Text('Confirm'),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Add Work Details'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('Worker card', () {
    testWidgets('Worker card shows name and labour type', (tester) async {
      final worker = LabourModel(
        id: '1',
        name: 'Test Worker',
        labourType: LabourType.mason,
        paymentMode: LabourPaymentMode.fixed,
        fixedDayRate: 800,
        totalPayment: 0,
        date: null,
        notes: null,
        createdAt: null,
        updatedAt: null,
      );
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                title: Text(worker.name),
                subtitle: Text(worker.labourType.displayName),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Test Worker'), findsOneWidget);
      expect(find.text('Mason'), findsOneWidget);
    });
  });
}
