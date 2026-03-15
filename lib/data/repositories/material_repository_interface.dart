import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/material_model.dart';

/// Abstract interface for material persistence. Allows tests to use a fake.
abstract class MaterialRepositoryInterface {
  Stream<List<MaterialModel>> streamMaterials({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  });
}
