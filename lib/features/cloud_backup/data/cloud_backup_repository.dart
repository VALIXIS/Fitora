import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitora/core/utils/app_logger.dart';
import 'package:fitora/features/cloud_backup/domain/cloud_backup_models.dart';

abstract class CloudBackupRepository {
  Future<CloudBackupPayload?> fetchBackup(String userId);
  Future<void> saveBackup(String userId, CloudBackupPayload payload);
  Future<void> deleteBackup(String userId);
}

class FirestoreCloudBackupRepository implements CloudBackupRepository {
  final FirebaseFirestore _firestore;

  FirestoreCloudBackupRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId).collection('cloud_backup').doc('v1_snapshot');
  }

  @override
  Future<CloudBackupPayload?> fetchBackup(String userId) async {
    if (userId.isEmpty) return null;

    try {
      final doc = await _userDoc(userId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      final data = doc.data()!;
      return CloudBackupPayload.fromJson(data);
    } catch (e, st) {
      AppLogger.error('Failed to fetch cloud backup for user $userId: $e', st);
      rethrow;
    }
  }

  @override
  Future<void> saveBackup(String userId, CloudBackupPayload payload) async {
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty when saving cloud backup');
    }

    try {
      final docRef = _userDoc(userId);
      final json = payload.toJson();
      // Enforce server timestamp metadata for sync tracking
      json['serverTimestamp'] = FieldValue.serverTimestamp();
      await docRef.set(json, SetOptions(merge: true));
      AppLogger.info('Successfully saved cloud backup for user $userId');
    } catch (e, st) {
      AppLogger.error('Failed to save cloud backup for user $userId: $e', st);
      rethrow;
    }
  }

  @override
  Future<void> deleteBackup(String userId) async {
    if (userId.isEmpty) return;

    try {
      await _userDoc(userId).delete();
      AppLogger.info('Successfully deleted cloud backup for user $userId');
    } catch (e, st) {
      AppLogger.error('Failed to delete cloud backup for user $userId: $e', st);
      rethrow;
    }
  }
}

/// In-Memory / Local Fallback Repository for unit testing and offline simulation.
class MemoryCloudBackupRepository implements CloudBackupRepository {
  final Map<String, CloudBackupPayload> _storage = {};

  @override
  Future<CloudBackupPayload?> fetchBackup(String userId) async {
    return _storage[userId];
  }

  @override
  Future<void> saveBackup(String userId, CloudBackupPayload payload) async {
    _storage[userId] = payload;
  }

  @override
  Future<void> deleteBackup(String userId) async {
    _storage.remove(userId);
  }
}
