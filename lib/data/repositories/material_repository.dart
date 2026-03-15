import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/storage_datasource.dart';
import '../models/material_model.dart';
import 'material_repository_interface.dart';

class MaterialRepository implements MaterialRepositoryInterface {
  MaterialRepository({
    FirestoreDatasource? firestore,
    StorageDatasource? storage,
  })  : _firestore = firestore ?? FirestoreDatasource(),
        _storage = storage ?? StorageDatasource();

  final FirestoreDatasource _firestore;
  final StorageDatasource _storage;

  @override
  Stream<List<MaterialModel>> streamMaterials({
    int limit = AppConstants.defaultPageSize,
    DocumentSnapshot? startAfter,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) {
    return _firestore.streamMaterials(
      limit: limit,
      startAfter: startAfter,
      category: category,
      fromDate: fromDate,
      toDate: toDate,
      searchQuery: searchQuery,
    );
  }

  Future<List<MaterialModel>> getMaterialsPaginated({
    int limit = AppConstants.defaultPageSize,
    DocumentSnapshot? startAfter,
  }) =>
      _firestore.getMaterialsPaginated(limit: limit, startAfter: startAfter);

  Future<MaterialModel?> getById(String id) => _firestore.getMaterialById(id);

  Future<void> addMaterial(MaterialModel model) async {
    await _firestore.addMaterial(model);
  }

  Future<void> updateMaterial(MaterialModel model) async {
    await _firestore.updateMaterial(model);
  }

  Future<void> deleteMaterial(String id) async {
    await _firestore.deleteMaterial(id);
  }

  Future<double> getTotalMaterialCost() => _firestore.getTotalMaterialCost();

  Future<Map<String, double>> getMaterialCostByCategory() =>
      _firestore.getMaterialCostByCategory();

  Future<String?> uploadBillImage(File? file) async {
    if (file == null || !await file.exists()) return null;
    return _storage.uploadBillImage(file);
  }

  Future<void> deleteBillImage(String? url) async {
    if (url == null || url.isEmpty) return;
    await _storage.deleteBillImage(url);
  }
}
