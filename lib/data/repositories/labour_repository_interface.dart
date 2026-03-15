import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/labour_model.dart';

/// Abstract interface for labour (workers) persistence. Allows tests to use a fake.
abstract class LabourRepositoryInterface {
  Stream<List<LabourModel>> streamLabour({
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  });
}
