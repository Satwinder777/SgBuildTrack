import 'package:flutter_test/flutter_test.dart';
import 'package:personal_construction_manager/core/services/payment_calculator.dart';
import 'package:personal_construction_manager/data/models/attendance_model.dart';
import 'package:personal_construction_manager/data/models/labour_model.dart';

LabourModel hourlyWorker({double rate = 100}) => LabourModel(
      id: 'w1',
      name: 'Hourly',
      labourType: LabourType.helper,
      paymentMode: LabourPaymentMode.hourly,
      hourlyRate: rate,
      fixedDayRate: null,
      totalPayment: 0,
      date: null,
      notes: null,
      createdAt: null,
      updatedAt: null,
    );

LabourModel dailyWorker({double dailyRate = 800}) => LabourModel(
      id: 'w2',
      name: 'Daily',
      labourType: LabourType.mason,
      paymentMode: LabourPaymentMode.fixed,
      hourlyRate: null,
      fixedDayRate: dailyRate,
      totalPayment: 0,
      date: null,
      notes: null,
      createdAt: null,
      updatedAt: null,
    );

void main() {
  group('PaymentCalculator', () {
    group('paymentForAttendance', () {
      test('hourly: 8 hours at 100 -> 800', () {
        final att = AttendanceModel(
          id: 'a1',
          workerId: 'w1',
          date: DateTime.now(),
          hoursWorked: 8,
          overtimeHours: 0,
          attendanceType: AttendanceType.fullDay,
        );
        expect(
          PaymentCalculator.paymentForAttendance(attendance: att, worker: hourlyWorker()),
          800,
        );
      });

      test('hourly: 8 + 2 overtime at 100 -> 1000', () {
        final att = AttendanceModel(
          id: 'a1',
          workerId: 'w1',
          date: DateTime.now(),
          hoursWorked: 8,
          overtimeHours: 2,
          attendanceType: AttendanceType.overtime,
        );
        expect(
          PaymentCalculator.paymentForAttendance(attendance: att, worker: hourlyWorker()),
          1000,
        );
      });

      test('daily full day -> dailyRate', () {
        final att = AttendanceModel(
          id: 'a1',
          workerId: 'w2',
          date: DateTime.now(),
          hoursWorked: 8,
          overtimeHours: 0,
          attendanceType: AttendanceType.fullDay,
        );
        expect(
          PaymentCalculator.paymentForAttendance(attendance: att, worker: dailyWorker()),
          800,
        );
      });

      test('daily half day -> dailyRate/2', () {
        final att = AttendanceModel(
          id: 'a1',
          workerId: 'w2',
          date: DateTime.now(),
          hoursWorked: 4,
          overtimeHours: 0,
          attendanceType: AttendanceType.halfDay,
        );
        expect(
          PaymentCalculator.paymentForAttendance(attendance: att, worker: dailyWorker()),
          400,
        );
      });

      test('daily absent -> 0', () {
        final att = AttendanceModel(
          id: 'a1',
          workerId: 'w2',
          date: DateTime.now(),
          hoursWorked: 0,
          overtimeHours: 0,
          attendanceType: AttendanceType.absent,
        );
        expect(
          PaymentCalculator.paymentForAttendance(attendance: att, worker: dailyWorker()),
          0,
        );
      });

      test('daily leave -> 0', () {
        final att = AttendanceModel(
          id: 'a1',
          workerId: 'w2',
          date: DateTime.now(),
          hoursWorked: 0,
          overtimeHours: 0,
          attendanceType: AttendanceType.leave,
        );
        expect(
          PaymentCalculator.paymentForAttendance(attendance: att, worker: dailyWorker()),
          0,
        );
      });

      test('daily overtime: base daily + overtime amount', () {
        final att = AttendanceModel(
          id: 'a1',
          workerId: 'w2',
          date: DateTime.now(),
          hoursWorked: 8,
          overtimeHours: 2,
          attendanceType: AttendanceType.overtime,
        );
        final w = dailyWorker(dailyRate: 800);
        // base 800 + overtime 2 * (800/8) = 800 + 200 = 1000
        expect(
          PaymentCalculator.paymentForAttendance(attendance: att, worker: w),
          1000,
        );
      });
    });

    group('totalEarningsFromAttendance', () {
      test('sums multiple attendances', () {
        final list = [
          AttendanceModel(
            id: 'a1',
            workerId: 'w1',
            date: DateTime.now(),
            hoursWorked: 8,
            overtimeHours: 0,
            attendanceType: AttendanceType.fullDay,
          ),
          AttendanceModel(
            id: 'a2',
            workerId: 'w1',
            date: DateTime.now(),
            hoursWorked: 4,
            overtimeHours: 0,
            attendanceType: AttendanceType.halfDay,
          ),
        ];
        expect(
          PaymentCalculator.totalEarningsFromAttendance(attendances: list, worker: hourlyWorker(rate: 100)),
          800 + 400,
        );
      });
    });

    group('pendingAmount', () {
      test('earnings - paid', () {
        expect(PaymentCalculator.pendingAmount(totalEarnings: 1000, totalPaid: 300), 700);
      });
      test('never negative', () {
        expect(PaymentCalculator.pendingAmount(totalEarnings: 100, totalPaid: 500), 0);
      });
    });
  });
}
