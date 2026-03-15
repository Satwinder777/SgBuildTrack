import 'package:flutter_test/flutter_test.dart';
import 'package:personal_construction_manager/core/services/attendance_service.dart';

void main() {
  group('AttendanceService', () {
    group('timeToMinutes', () {
      test('parses HH:mm', () {
        expect(AttendanceService.timeToMinutes('09:00'), 9 * 60);
        expect(AttendanceService.timeToMinutes('17:30'), 17 * 60 + 30);
        expect(AttendanceService.timeToMinutes('00:00'), 0);
      });
      test('returns null for invalid', () {
        expect(AttendanceService.timeToMinutes(null), isNull);
        expect(AttendanceService.timeToMinutes(''), isNull);
        expect(AttendanceService.timeToMinutes('25:00'), isNull);
      });
    });

    group('calculateHoursWorked', () {
      test('8 hours between 09:00 and 17:00', () {
        expect(
          AttendanceService.calculateHoursWorked(checkInTime: '09:00', checkOutTime: '17:00'),
          8.0,
        );
      });
      test('10 hours between 09:00 and 19:00', () {
        expect(
          AttendanceService.calculateHoursWorked(checkInTime: '09:00', checkOutTime: '19:00'),
          10.0,
        );
      });
      test('0 when check-out before check-in', () {
        expect(
          AttendanceService.calculateHoursWorked(checkInTime: '17:00', checkOutTime: '09:00'),
          0.0,
        );
      });
      test('0 when invalid times', () {
        expect(
          AttendanceService.calculateHoursWorked(checkInTime: null, checkOutTime: '17:00'),
          0.0,
        );
      });
    });

    group('calculateOvertime', () {
      test('total 8 -> regular 8, overtime 0', () {
        final r = AttendanceService.calculateOvertime(8);
        expect(r.$1, 8.0);
        expect(r.$2, 0.0);
      });
      test('total 10 -> regular 8, overtime 2', () {
        final r = AttendanceService.calculateOvertime(10);
        expect(r.$1, 8.0);
        expect(r.$2, 2.0);
      });
      test('total 16 -> regular 8, overtime 8 (capped)', () {
        final r = AttendanceService.calculateOvertime(16);
        expect(r.$1, 8.0);
        expect(r.$2, 8.0);
      });
      test('total 20 -> regular 8, overtime 8 (capped)', () {
        final r = AttendanceService.calculateOvertime(20);
        expect(r.$1, 8.0);
        expect(r.$2, 8.0);
      });
      test('total 4 -> regular 4, overtime 0', () {
        final r = AttendanceService.calculateOvertime(4);
        expect(r.$1, 4.0);
        expect(r.$2, 0.0);
      });
    });

    group('calculateHoursAndOvertime', () {
      test('09:00 to 19:00 -> 8 regular, 2 overtime', () {
        final r = AttendanceService.calculateHoursAndOvertime(
          checkInTime: '09:00',
          checkOutTime: '19:00',
        );
        expect(r.$1, 8.0);
        expect(r.$2, 2.0);
      });
      test('09:00 to 17:00 -> 8 regular, 0 overtime', () {
        final r = AttendanceService.calculateHoursAndOvertime(
          checkInTime: '09:00',
          checkOutTime: '17:00',
        );
        expect(r.$1, 8.0);
        expect(r.$2, 0.0);
      });
    });

    group('clampHours / clampOvertime', () {
      test('clampHours caps at 16', () {
        expect(AttendanceService.clampHours(20), 16.0);
        expect(AttendanceService.clampHours(8), 8.0);
      });
      test('clampOvertime caps at 8', () {
        expect(AttendanceService.clampOvertime(10), 8.0);
        expect(AttendanceService.clampOvertime(2), 2.0);
      });
    });
  });
}
