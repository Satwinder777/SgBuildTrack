import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/material_model.dart';
import '../models/labour_model.dart';
import '../models/attendance_model.dart';
import '../models/worker_payment_record_model.dart';

/// Single Firestore datasource for materials, labour, attendance, worker payments.
/// Uses pagination and efficient queries.
class FirestoreDatasource {
  FirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _materials =>
      _firestore.collection(AppConstants.materialsCollection);
  CollectionReference<Map<String, dynamic>> get _labour =>
      _firestore.collection(AppConstants.labourCollection);
  CollectionReference<Map<String, dynamic>> get _attendance =>
      _firestore.collection(AppConstants.attendanceCollection);
  CollectionReference<Map<String, dynamic>> get _workerPayments =>
      _firestore.collection(AppConstants.workerPaymentsCollection);

  // ————— Materials —————
  Future<void> addMaterial(MaterialModel model) async {
    try {
      await _materials.doc(model.id).set(model.toFirestore());
      AppLogger.db('Material added', data: {'id': model.id, 'name': model.materialName});
    } catch (e, st) {
      AppLogger.error('Firestore addMaterial failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateMaterial(MaterialModel model) async {
    try {
      await _materials.doc(model.id).set(model.toFirestore(), SetOptions(merge: true));
      AppLogger.db('Material updated', data: {'id': model.id});
    } catch (e, st) {
      AppLogger.error('Firestore updateMaterial failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteMaterial(String id) async {
    try {
      await _materials.doc(id).delete();
      AppLogger.db('Material deleted', data: {'id': id});
    } catch (e, st) {
      AppLogger.error('Firestore deleteMaterial failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<MaterialModel?> getMaterialById(String id) async {
    try {
      final doc = await _materials.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return MaterialModel.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e, st) {
      AppLogger.error('Firestore getMaterialById failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Stream<List<MaterialModel>> streamMaterials({
    int limit = AppConstants.defaultPageSize,
    DocumentSnapshot? startAfter,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) {
    Query<Map<String, dynamic>> q = _materials
        .orderBy('createdAt', descending: true)
        .limit(limit * 2);
    if (category != null && category.isNotEmpty) {
      q = _materials
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .limit(limit * 2);
    }
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    return q.snapshots().map((snap) {
      var list = snap.docs.map((d) => MaterialModel.fromFirestore(d.data())).toList();
      if (fromDate != null) {
        list = list.where((m) => m.purchaseDate != null && !m.purchaseDate!.isBefore(fromDate)).toList();
      }
      if (toDate != null) {
        list = list.where((m) => m.purchaseDate != null && m.purchaseDate!.isBefore(toDate)).toList();
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lower = searchQuery.trim().toLowerCase();
        final num? amount = num.tryParse(searchQuery.trim());
        list = list.where((m) {
          if (m.materialName.toLowerCase().contains(lower)) return true;
          if (m.supplierName?.toLowerCase().contains(lower) ?? false) return true;
          if (m.category.displayName.toLowerCase().contains(lower)) return true;
          if (amount != null) {
            if ((m.totalPrice - amount).abs() < 0.01) return true;
            if ((m.pricePerUnit - amount).abs() < 0.01) return true;
          }
          return false;
        }).toList();
      }
      return list.take(limit).toList();
    });
  }

  Future<List<MaterialModel>> getMaterialsPaginated({
    int limit = AppConstants.defaultPageSize,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _materials
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    return snap.docs.map((d) => MaterialModel.fromFirestore(d.data())).toList();
  }

  Future<double> getTotalMaterialCost() async {
    try {
      final snap = await _materials.get();
      final total = snap.docs.fold<double>(0.0, (double sum, d) {
        final data = d.data();
        return sum + ((data['totalPrice'] as num?)?.toDouble() ?? 0);
      });
      AppLogger.calc('getTotalMaterialCost', data: {'total': total});
      return total;
    } catch (e, st) {
      AppLogger.error('Firestore getTotalMaterialCost failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Map<String, double>> getMaterialCostByCategory() async {
    try {
      final snap = await _materials.get();
      final map = <String, double>{};
      for (final d in snap.docs) {
        final data = d.data();
        final cat = data['category'] as String? ?? 'other';
        final total = (data['totalPrice'] as num?)?.toDouble() ?? 0;
        map[cat] = (map[cat] ?? 0) + total;
      }
      AppLogger.calc('getMaterialCostByCategory', data: {'categories': map.length});
      return map;
    } catch (e, st) {
      AppLogger.error('Firestore getMaterialCostByCategory failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ————— Labour —————
  Future<void> addLabour(LabourModel model) async {
    try {
      await _labour.doc(model.id).set(model.toFirestore());
      AppLogger.db('Labour added', data: {'id': model.id, 'name': model.name});
    } catch (e, st) {
      AppLogger.error('Firestore addLabour failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateLabour(LabourModel model) async {
    try {
      await _labour.doc(model.id).set(model.toFirestore(), SetOptions(merge: true));
      AppLogger.db('Labour updated', data: {'id': model.id});
    } catch (e, st) {
      AppLogger.error('Firestore updateLabour failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteLabour(String id) async {
    try {
      await _labour.doc(id).delete();
      AppLogger.db('Labour deleted', data: {'id': id});
    } catch (e, st) {
      AppLogger.error('Firestore deleteLabour failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<LabourModel?> getLabourById(String id) async {
    try {
      final doc = await _labour.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return LabourModel.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e, st) {
      AppLogger.error('Firestore getLabourById failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Stream<List<LabourModel>> streamLabour({
    int limit = AppConstants.defaultPageSize,
    DocumentSnapshot? startAfter,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) {
    Query<Map<String, dynamic>> q = _labour
        .orderBy('createdAt', descending: true)
        .limit(limit * 2);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    return q.snapshots().map((snap) {
      var list = snap.docs.map((d) => LabourModel.fromFirestore(d.data())).toList();
      if (fromDate != null) {
        list = list.where((l) {
          final d = l.date ?? l.createdAt;
          return d != null && !d.isBefore(fromDate);
        }).toList();
      }
      if (toDate != null) {
        list = list.where((l) {
          final d = l.date ?? l.createdAt;
          return d != null && d.isBefore(toDate);
        }).toList();
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lower = searchQuery.trim().toLowerCase();
        final amount = num.tryParse(searchQuery.trim());
        list = list.where((l) {
          if (l.name.toLowerCase().contains(lower)) return true;
          if (l.labourType.displayName.toLowerCase().contains(lower)) return true;
          if (amount != null && (l.totalPayment - amount).abs() < 0.01) return true;
          return false;
        }).toList();
      }
      return list.take(limit).toList();
    });
  }

  Future<double> getTotalLabourCost() async {
    try {
      final snap = await _labour.get();
      final total = snap.docs.fold<double>(0.0, (double sum, d) {
        final data = d.data();
        return sum + ((data['totalPayment'] as num?)?.toDouble() ?? 0);
      });
      AppLogger.calc('getTotalLabourCost', data: {'total': total});
      return total;
    } catch (e, st) {
      AppLogger.error('Firestore getTotalLabourCost failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ————— Attendance —————
  Future<void> addAttendance(AttendanceModel model) async {
    try {
      await _attendance.doc(model.id).set(model.toFirestore());
      AppLogger.db('Attendance added', data: {'id': model.id, 'workerId': model.workerId});
    } catch (e, st) {
      AppLogger.error('Firestore addAttendance failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateAttendance(AttendanceModel model) async {
    try {
      await _attendance.doc(model.id).set(model.toFirestore(), SetOptions(merge: true));
      AppLogger.db('Attendance updated', data: {'id': model.id});
    } catch (e, st) {
      AppLogger.error('Firestore updateAttendance failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteAttendance(String id) async {
    try {
      await _attendance.doc(id).delete();
      AppLogger.db('Attendance deleted', data: {'id': id});
    } catch (e, st) {
      AppLogger.error('Firestore deleteAttendance failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<AttendanceModel?> getAttendanceByWorkerAndDate(String workerId, DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final snap = await _attendance
          .where('workerId', isEqualTo: workerId)
          .where('date', isEqualTo: dateStr)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return AttendanceModel.fromFirestore(snap.docs.first.data());
    } catch (e, st) {
      AppLogger.error('Firestore getAttendanceByWorkerAndDate failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Realtime stream for a single day (indexed query by date). Use for pending/present/absent lists.
  Stream<List<AttendanceModel>> streamAttendanceForDate(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _attendance
        .where('date', isEqualTo: dateStr)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AttendanceModel.fromFirestore(d.data())).toList());
  }

  Stream<List<AttendanceModel>> streamAttendance({
    String? workerId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) {
    final q = _attendance.orderBy('date', descending: true).limit(limit * 2);
    return q.snapshots().map((snap) {
      var list = snap.docs.map((d) => AttendanceModel.fromFirestore(d.data())).toList();
      if (workerId != null && workerId.isNotEmpty) {
        list = list.where((a) => a.workerId == workerId).toList();
      }
      if (fromDate != null) {
        final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
        list = list.where((a) => !a.date.isBefore(from)).toList();
      }
      if (toDate != null) {
        final to = DateTime(toDate.year, toDate.month, toDate.day).add(const Duration(days: 1));
        list = list.where((a) => a.date.isBefore(to)).toList();
      }
      return list.take(limit).toList();
    });
  }

  // ————— Worker Payments —————
  Future<void> addWorkerPayment(WorkerPaymentRecordModel model) async {
    try {
      await _workerPayments.doc(model.id).set(model.toFirestore());
      AppLogger.db('Worker payment added', data: {'id': model.id, 'workerId': model.workerId});
    } catch (e, st) {
      AppLogger.error('Firestore addWorkerPayment failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Realtime stream of payments for a single worker (indexed: workerId + paymentDate).
  Stream<List<WorkerPaymentRecordModel>> streamPaymentsForWorker(String workerId, {int limit = 100}) {
    if (workerId.isEmpty) return Stream.value([]);
    final q = _workerPayments
        .where('workerId', isEqualTo: workerId)
        .orderBy('paymentDate', descending: true)
        .limit(limit);
    return q.snapshots().map(
        (snap) => snap.docs.map((d) => WorkerPaymentRecordModel.fromFirestore(d.data())).toList());
  }

  /// Realtime stream of all worker payments (for summary list). No workerId filter in query.
  Stream<List<WorkerPaymentRecordModel>> streamWorkerPayments({
    String? workerId,
    int limit = 100,
  }) {
    if (workerId != null && workerId.isNotEmpty) {
      return streamPaymentsForWorker(workerId, limit: limit);
    }
    final q = _workerPayments.orderBy('paymentDate', descending: true).limit(limit * 2);
    return q.snapshots().map((snap) {
      return snap.docs
          .map((d) => WorkerPaymentRecordModel.fromFirestore(d.data()))
          .take(limit)
          .toList();
    });
  }
}
