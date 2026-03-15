import '../datasources/firestore_datasource.dart';
import '../models/attendance_model.dart';
import 'attendance_repository_interface.dart';

class AttendanceRepository implements AttendanceRepositoryInterface {
  AttendanceRepository({FirestoreDatasource? firestore})
      : _firestore = firestore ?? FirestoreDatasource();

  final FirestoreDatasource _firestore;

  @override
  Future<void> addAttendance(AttendanceModel model) => _firestore.addAttendance(model);

  @override
  Future<void> updateAttendance(AttendanceModel model) => _firestore.updateAttendance(model);

  @override
  Future<void> deleteAttendance(String id) => _firestore.deleteAttendance(id);

  @override
  Future<AttendanceModel?> getByWorkerAndDate(String workerId, DateTime date) =>
      _firestore.getAttendanceByWorkerAndDate(workerId, date);

  @override
  Stream<List<AttendanceModel>> streamAttendanceForDate(DateTime date) =>
      _firestore.streamAttendanceForDate(date);

  @override
  Stream<List<AttendanceModel>> streamAttendance({
    String? workerId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) =>
      _firestore.streamAttendance(
        workerId: workerId,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
      );
}
