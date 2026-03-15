import '../models/worker_payment_record_model.dart';

/// Abstract interface for worker payment persistence. Allows tests to use a fake.
abstract class WorkerPaymentRepositoryInterface {
  Future<void> addWorkerPayment(WorkerPaymentRecordModel model);
  Stream<List<WorkerPaymentRecordModel>> streamWorkerPayments({
    String? workerId,
    int limit = 100,
  });
}
