import '../models/attendance_model.dart';

/// Abstract interface for attendance persistence. Allows tests to use a fake.
abstract class AttendanceRepositoryInterface {
  Future<void> addAttendance(AttendanceModel model);
  Future<void> updateAttendance(AttendanceModel model);
  Future<void> deleteAttendance(String id);
  Future<AttendanceModel?> getByWorkerAndDate(String workerId, DateTime date);
  Stream<List<AttendanceModel>> streamAttendanceForDate(DateTime date);
  Stream<List<AttendanceModel>> streamAttendance({
    String? workerId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  });
}
