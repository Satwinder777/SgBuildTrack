import '../datasources/firestore_datasource.dart';
import '../models/worker_payment_record_model.dart';
import 'worker_payment_repository_interface.dart';

class WorkerPaymentRepository implements WorkerPaymentRepositoryInterface {
  WorkerPaymentRepository({FirestoreDatasource? firestore})
      : _firestore = firestore ?? FirestoreDatasource();

  final FirestoreDatasource _firestore;

  @override
  Future<void> addWorkerPayment(WorkerPaymentRecordModel model) =>
      _firestore.addWorkerPayment(model);

  /// Realtime stream for a single worker's payments (indexed query).
  Stream<List<WorkerPaymentRecordModel>> streamPaymentsForWorker(String workerId, {int limit = 100}) =>
      _firestore.streamPaymentsForWorker(workerId, limit: limit);

  @override
  Stream<List<WorkerPaymentRecordModel>> streamWorkerPayments({
    String? workerId,
    int limit = 100,
  }) =>
      _firestore.streamWorkerPayments(workerId: workerId, limit: limit);
}
