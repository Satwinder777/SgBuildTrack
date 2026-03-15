import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

/// Upload and download bill images from Firebase Storage.
class StorageDatasource {
  StorageDatasource({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  Reference get _billsRef => _storage.ref().child(AppConstants.billImagesPath);

  /// Uploads bill image to Firebase Storage. Returns null if storage is unavailable or fails
  /// (app continues without bill image).
  Future<String?> uploadBillImage(File file) async {
    try {
      final name = '${_uuid.v4()}.jpg';
      final ref = _billsRef.child(name);
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      AppLogger.api('Bill image uploaded', data: {'name': name});
      return url;
    } catch (e, st) {
      AppLogger.error('Storage uploadBillImage failed (optional)', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> deleteBillImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      AppLogger.api('Bill image deleted', data: {'url': url});
    } catch (e, st) {
      AppLogger.error('Storage deleteBillImage failed (may be already deleted)', error: e, stackTrace: st);
      // Do not rethrow so callers are not broken when file is already gone
    }
  }
}
