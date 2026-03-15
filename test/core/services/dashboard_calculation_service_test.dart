import 'package:flutter_test/flutter_test.dart';
import 'package:personal_construction_manager/core/services/dashboard_calculation_service.dart';
import 'package:personal_construction_manager/data/models/attendance_model.dart';
import 'package:personal_construction_manager/data/models/labour_model.dart';
import 'package:personal_construction_manager/data/models/material_model.dart';
import 'package:personal_construction_manager/data/models/worker_payment_record_model.dart';

LabourModel worker({String id = 'w1', double? hourlyRate, double? fixedDayRate}) =>
    LabourModel(
      id: id,
      name: 'Test',
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

AttendanceModel att({
  required String workerId,
  bool present = true,
  double hours = 8,
  AttendanceType type = AttendanceType.fullDay,
  DateTime? date,
}) =>
    AttendanceModel(
      id: 'a$workerId',
      workerId: workerId,
      date: date ?? DateTime.now(),
      hoursWorked: hours,
      overtimeHours: 0,
      attendanceType: type,
      attendanceStatus: present ? AttendanceStatus.present : AttendanceStatus.absent,
    );

MaterialModel material({double totalPrice = 100}) => MaterialModel(
      id: 'm1',
      category: MaterialCategory.cement,
      materialName: 'Cement',
      quantity: 1,
      unitType: MaterialUnit.bag,
      pricePerUnit: totalPrice,
      totalPrice: totalPrice,
    );

WorkerPaymentRecordModel wp({double amountPaid = 500}) => WorkerPaymentRecordModel(
      id: 'p1',
      workerId: 'w1',
      amountPaid: amountPaid,
      paymentDate: DateTime.now(),
    );

void main() {
  group('DashboardCalculationService', () {
    group('calculateTotalWorkers', () {
      test('empty list -> 0', () {
        expect(DashboardCalculationService.calculateTotalWorkers([]), 0);
      });
      test('three workers -> 3', () {
        expect(
          DashboardCalculationService.calculateTotalWorkers([
            worker(id: '1'),
            worker(id: '2'),
            worker(id: '3'),
          ]),
          3,
        );
      });
    });

    group('calculatePresentToday', () {
      test('empty -> 0', () {
        expect(DashboardCalculationService.calculatePresentToday([]), 0);
      });
      test('two present one absent -> 2', () {
        expect(
          DashboardCalculationService.calculatePresentToday([
            att(workerId: 'w1', present: true),
            att(workerId: 'w2', present: true),
            att(workerId: 'w3', present: false),
          ]),
          2,
        );
      });
    });

    group('calculateAbsentToday', () {
      test('one absent -> 1', () {
        expect(
          DashboardCalculationService.calculateAbsentToday([
            att(workerId: 'w1', present: false),
          ]),
          1,
        );
      });
    });

    group('calculateTotalHoursToday', () {
      test('sum of hours', () {
        expect(
          DashboardCalculationService.calculateTotalHoursToday([
            att(workerId: 'w1', hours: 8),
            att(workerId: 'w2', hours: 4),
          ]),
          12,
        );
      });
    });

    group('calculateTodayLabourCost', () {
      test('hourly worker 8h @ 100 -> 800', () {
        final workers = [worker(id: 'w1', hourlyRate: 100)];
        final attToday = [att(workerId: 'w1', hours: 8)];
        expect(
          DashboardCalculationService.calculateTodayLabourCost(
            attendanceToday: attToday,
            workers: workers,
          ),
          800,
        );
      });
      test('daily worker full day 800 -> 800', () {
        final workers = [worker(id: 'w2', fixedDayRate: 800)];
        final attToday = [att(workerId: 'w2', type: AttendanceType.fullDay)];
        expect(
          DashboardCalculationService.calculateTodayLabourCost(
            attendanceToday: attToday,
            workers: workers,
          ),
          800,
        );
      });
      test('unknown worker skipped', () {
        final workers = [worker(id: 'w1')];
        final attToday = [att(workerId: 'wOther', hours: 8)];
        expect(
          DashboardCalculationService.calculateTodayLabourCost(
            attendanceToday: attToday,
            workers: workers,
          ),
          0,
        );
      });
    });

    group('calculateTotalMaterialCost', () {
      test('empty -> 0', () {
        expect(DashboardCalculationService.calculateTotalMaterialCost([]), 0);
      });
      test('sum totalPrice', () {
        expect(
          DashboardCalculationService.calculateTotalMaterialCost([
            material(totalPrice: 100),
            material(totalPrice: 200),
          ]),
          300,
        );
      });
    });

    group('calculateTotalPaymentsMade', () {
      test('sum amountPaid', () {
        expect(
          DashboardCalculationService.calculateTotalPaymentsMade([
            wp(amountPaid: 300),
            wp(amountPaid: 200),
          ]),
          500,
        );
      });
    });

    group('calculatePendingPayments', () {
      test('earnings - paid', () {
        expect(
          DashboardCalculationService.calculatePendingPayments(
            totalLabourEarnings: 1000,
            totalPaymentsMade: 400,
          ),
          600,
        );
      });
      test('never negative', () {
        expect(
          DashboardCalculationService.calculatePendingPayments(
            totalLabourEarnings: 100,
            totalPaymentsMade: 500,
          ),
          0,
        );
      });
    });

    group('calculateMaterialCostByCategory', () {
      test('groups by category', () {
        final materials = [
          MaterialModel(
            id: '1',
            category: MaterialCategory.cement,
            materialName: 'C1',
            quantity: 1,
            unitType: MaterialUnit.bag,
            pricePerUnit: 100,
            totalPrice: 100,
          ),
          MaterialModel(
            id: '2',
            category: MaterialCategory.cement,
            materialName: 'C2',
            quantity: 1,
            unitType: MaterialUnit.bag,
            pricePerUnit: 50,
            totalPrice: 50,
          ),
          MaterialModel(
            id: '3',
            category: MaterialCategory.sand,
            materialName: 'S1',
            quantity: 1,
            unitType: MaterialUnit.cubicMeter,
            pricePerUnit: 200,
            totalPrice: 200,
          ),
        ];
        final map = DashboardCalculationService.calculateMaterialCostByCategory(materials);
        expect(map['Cement'], 150);
        expect(map['Sand'], 200);
      });
    });

    group('calculateLabourCostByDay', () {
      test('aggregates labour cost per day in range', () {
        final workers = [worker(id: 'w1', hourlyRate: 100)];
        final start = DateTime(2025, 3, 1);
        final end = DateTime(2025, 3, 3);
        final attendance = [
          att(workerId: 'w1', hours: 8, date: DateTime(2025, 3, 1)),
          att(workerId: 'w1', hours: 4, type: AttendanceType.halfDay, date: DateTime(2025, 3, 2)),
        ];
        final map = DashboardCalculationService.calculateLabourCostByDay(
          attendance: attendance,
          workers: workers,
          startDate: start,
          endDate: end,
        );
        expect(map[DateTime(2025, 3, 1)], 800);
        expect(map[DateTime(2025, 3, 2)], 400);
      });
    });

    group('calculateAttendanceByDay', () {
      test('aggregates present and absent per day in range', () {
        final start = DateTime(2025, 3, 1);
        final end = DateTime(2025, 3, 2);
        final attendance = [
          att(workerId: 'w1', present: true, date: DateTime(2025, 3, 1)),
          att(workerId: 'w2', present: false, date: DateTime(2025, 3, 1)),
          att(workerId: 'w3', present: true, date: DateTime(2025, 3, 2)),
        ];
        final map = DashboardCalculationService.calculateAttendanceByDay(
          attendance: attendance,
          startDate: start,
          endDate: end,
        );
        expect(map[DateTime(2025, 3, 1)]!.present, 1);
        expect(map[DateTime(2025, 3, 1)]!.absent, 1);
        expect(map[DateTime(2025, 3, 2)]!.present, 1);
        expect(map[DateTime(2025, 3, 2)]!.absent, 0);
      });
    });
  });
}
