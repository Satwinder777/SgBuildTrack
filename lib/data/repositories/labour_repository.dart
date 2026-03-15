import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../datasources/firestore_datasource.dart';
import '../models/labour_model.dart';
import 'labour_repository_interface.dart';

class LabourRepository implements LabourRepositoryInterface {
  LabourRepository({FirestoreDatasource? firestore})
      : _firestore = firestore ?? FirestoreDatasource();

  final FirestoreDatasource _firestore;

  @override
  Stream<List<LabourModel>> streamLabour({
    int limit = AppConstants.defaultPageSize,
    DocumentSnapshot? startAfter,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) {
    return _firestore.streamLabour(
      limit: limit,
      startAfter: startAfter,
      fromDate: fromDate,
      toDate: toDate,
      searchQuery: searchQuery,
    );
  }

  Future<LabourModel?> getById(String id) => _firestore.getLabourById(id);

  Future<void> addLabour(LabourModel model) async {
    await _firestore.addLabour(model);
  }

  Future<void> updateLabour(LabourModel model) async {
    await _firestore.updateLabour(model);
  }

  Future<void> deleteLabour(String id) async {
    await _firestore.deleteLabour(id);
  }

  Future<double> getTotalLabourCost() => _firestore.getTotalLabourCost();
}
