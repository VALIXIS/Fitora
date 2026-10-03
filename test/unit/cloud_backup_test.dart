import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/storage/local_database_service.dart';
import 'package:fitora/features/cloud_backup/data/cloud_backup_repository.dart';
import 'package:fitora/features/cloud_backup/domain/cloud_backup_models.dart';
import 'package:fitora/features/cloud_backup/services/cloud_backup_sync_service.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/cycle/domain/cycle_models.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late MemoryCloudBackupRepository memoryRepo;
  late LocalDatabaseService localDb;
  late CloudBackupSyncService syncService;

  setUp(() async {
    AppPreferences.resetForTests();
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.initialize();

    memoryRepo = MemoryCloudBackupRepository();
    final db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE daily_logs (
          date TEXT PRIMARY KEY,
          steps INTEGER DEFAULT 0,
          calories_burned REAL DEFAULT 0.0,
          water_liters REAL DEFAULT 0.0,
          sleep_minutes INTEGER DEFAULT 0,
          distance_km REAL DEFAULT 0.0,
          active_minutes INTEGER DEFAULT 0,
          updated_at TEXT NOT NULL
        );
      ''');
    });
    localDb = LocalDatabaseService(db);
    syncService = CloudBackupSyncService(
      repository: memoryRepo,
      localDb: localDb,
    );
  });

  group('Cloud Backup & Restore System Tests', () {
    test('Initial backup saves complete local dataset to cloud', () async {
      const userId = 'user-123';

      // Seed local storage
      final now = DateTime.now();
      final workout = WorkoutLogEntry(
        id: 'w-1',
        activityType: WorkoutActivityType.running,
        durationMinutes: 30,
        estimatedCalories: 250,
        timestamp: now,
        notes: 'Morning run',
      );
      final periodRange = PeriodRange(
        id: 'p-1',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 5),
        notes: 'Regular period',
      );

      final localPayload = CloudBackupPayload(
        userId: userId,
        updatedAt: now,
        workouts: [workout],
        periodRanges: [periodRange],
      );

      await syncService.restoreToLocal(localPayload);

      // Perform sync
      final syncTime = await syncService.performSync(userId);
      expect(syncTime, isNotNull);

      // Verify cloud repository received payload
      final cloudBackup = await memoryRepo.fetchBackup(userId);
      expect(cloudBackup, isNotNull);
      expect(cloudBackup!.userId, equals(userId));
      expect(cloudBackup.workouts.length, equals(1));
      expect(cloudBackup.workouts.first.id, equals('w-1'));
      expect(cloudBackup.periodRanges.length, equals(1));
      expect(cloudBackup.periodRanges.first.id, equals('p-1'));
    });

    test('Two-Way Deterministic Merge preserves local and cloud unique records', () {
      const userId = 'user-123';
      final now = DateTime.now();

      final localWorkout = WorkoutLogEntry(
        id: 'w-local',
        activityType: WorkoutActivityType.cycling,
        durationMinutes: 45,
        estimatedCalories: 300,
        timestamp: now,
      );

      final cloudWorkout = WorkoutLogEntry(
        id: 'w-cloud',
        activityType: WorkoutActivityType.walking,
        durationMinutes: 60,
        estimatedCalories: 180,
        timestamp: now.subtract(const Duration(hours: 2)),
      );

      final localPayload = CloudBackupPayload(
        userId: userId,
        updatedAt: now,
        workouts: [localWorkout],
      );

      final cloudPayload = CloudBackupPayload(
        userId: userId,
        updatedAt: now.subtract(const Duration(hours: 1)),
        workouts: [cloudWorkout],
      );

      final merged = syncService.mergePayloads(localPayload, cloudPayload);

      expect(merged.workouts.length, equals(2));
      final ids = merged.workouts.map((w) => w.id).toSet();
      expect(ids, containsAll(['w-local', 'w-cloud']));
    });

    test('Conflicting records resolve via latest timestamp (last-write-wins)', () {
      const userId = 'user-123';
      final oldTime = DateTime(2026, 9, 1, 10, 0);
      final newTime = DateTime(2026, 9, 1, 12, 0);

      final oldWorkout = WorkoutLogEntry(
        id: 'w-same',
        activityType: WorkoutActivityType.hiit,
        durationMinutes: 20,
        estimatedCalories: 150,
        timestamp: oldTime,
        notes: 'Old notes',
      );

      final newWorkout = WorkoutLogEntry(
        id: 'w-same',
        activityType: WorkoutActivityType.hiit,
        durationMinutes: 25,
        estimatedCalories: 200,
        timestamp: newTime,
        notes: 'Updated notes',
      );

      final localPayload = CloudBackupPayload(
        userId: userId,
        updatedAt: newTime,
        workouts: [newWorkout],
      );

      final cloudPayload = CloudBackupPayload(
        userId: userId,
        updatedAt: oldTime,
        workouts: [oldWorkout],
      );

      final merged = syncService.mergePayloads(localPayload, cloudPayload);

      expect(merged.workouts.length, equals(1));
      expect(merged.workouts.first.durationMinutes, equals(25));
      expect(merged.workouts.first.notes, equals('Updated notes'));
    });

    test('Tombstones prevent deleted records from resurrecting', () {
      const userId = 'user-123';
      final now = DateTime.now();

      final cloudWorkout = WorkoutLogEntry(
        id: 'w-deleted',
        activityType: WorkoutActivityType.yoga,
        durationMinutes: 30,
        estimatedCalories: 100,
        timestamp: now.subtract(const Duration(days: 1)),
      );

      final localPayload = CloudBackupPayload(
        userId: userId,
        updatedAt: now,
        workouts: const [],
        tombstones: {'w-deleted': now.toIso8601String()},
      );

      final cloudPayload = CloudBackupPayload(
        userId: userId,
        updatedAt: now.subtract(const Duration(hours: 5)),
        workouts: [cloudWorkout],
      );

      final merged = syncService.mergePayloads(localPayload, cloudPayload);
      expect(merged.workouts, isEmpty);
    });

    test('Offline failure preserves local dataset 100%', () async {
      const userId = 'user-offline';

      final failingRepo = _FailingCloudBackupRepository();
      final failingSyncService = CloudBackupSyncService(
        repository: failingRepo,
        localDb: localDb,
      );

      final localRecord = DailyLogRecord(
        date: '2026-09-05',
        steps: 8500,
        waterLiters: 2.5,
      );
      await localDb.upsertDailyLog(localRecord);

      // Attempt sync
      final syncTime = await failingSyncService.performSync(userId);

      // Verify sync returns safe time and local data remains in SQLite
      expect(syncTime, isNotNull);
      final logs = await localDb.getAllDailyLogs();
      expect(logs.length, equals(1));
      expect(logs.first.steps, equals(8500));
    });

    test('End-to-End Zero Data Loss Scenario (Device A -> Cloud -> Device B -> Convergence)', () async {
      const userId = 'user-device-switch';
      final t1 = DateTime(2026, 9, 5, 10, 0);

      // --- DEVICE A ---
      final deviceAPayload = CloudBackupPayload(
        userId: userId,
        updatedAt: t1,
        profile: PersonalizationProfile(name: 'Krishna', age: 28, heightCm: 178, weightKg: 72),
        workouts: [
          WorkoutLogEntry(
            id: 'w-devA-1',
            activityType: WorkoutActivityType.running,
            durationMinutes: 40,
            estimatedCalories: 380,
            timestamp: t1,
          ),
        ],
        periodRanges: [
          PeriodRange(id: 'p-devA-1', startDate: DateTime(2026, 9, 1)),
        ],
      );

      await syncService.restoreToLocal(deviceAPayload);
      await syncService.performSync(userId);

      // --- DEVICE B ---
      // Device B starts clean, signs in with same account, performs Cloud Restore
      final deviceBMemoryRepo = memoryRepo; // Sharing same cloud storage
      final deviceBLocalDb = LocalDatabaseService(
        await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, v) async {
          await db.execute('''
            CREATE TABLE daily_logs (
              date TEXT PRIMARY KEY,
              steps INTEGER DEFAULT 0,
              calories_burned REAL DEFAULT 0.0,
              water_liters REAL DEFAULT 0.0,
              sleep_minutes INTEGER DEFAULT 0,
              distance_km REAL DEFAULT 0.0,
              active_minutes INTEGER DEFAULT 0,
              updated_at TEXT NOT NULL
            );
          ''');
        }),
      );

      final deviceBSyncService = CloudBackupSyncService(
        repository: deviceBMemoryRepo,
        localDb: deviceBLocalDb,
      );

      // Device B restores from cloud
      await deviceBSyncService.performSync(userId);
      final deviceBLocalSnapshot = await deviceBSyncService.buildLocalPayload(userId);

      // Verify Device B has Device A's complete dataset
      expect(deviceBLocalSnapshot.profile?.name, equals('Krishna'));
      expect(deviceBLocalSnapshot.workouts.length, equals(1));
      expect(deviceBLocalSnapshot.workouts.first.id, equals('w-devA-1'));
      expect(deviceBLocalSnapshot.periodRanges.length, equals(1));

      // Device B adds a new workout
      final t2 = DateTime(2026, 9, 5, 14, 0);
      final newWorkoutDevB = WorkoutLogEntry(
        id: 'w-devB-2',
        activityType: WorkoutActivityType.strengthTraining,
        durationMinutes: 50,
        estimatedCalories: 400,
        timestamp: t2,
      );

      final deviceBUpdatedPayload = CloudBackupPayload(
        userId: userId,
        updatedAt: t2,
        profile: deviceBLocalSnapshot.profile,
        workouts: [...deviceBLocalSnapshot.workouts, newWorkoutDevB],
        periodRanges: deviceBLocalSnapshot.periodRanges,
      );

      await deviceBSyncService.restoreToLocal(deviceBUpdatedPayload);
      await deviceBSyncService.performSync(userId);

      // --- RETURN TO DEVICE A ---
      // Device A syncs with Cloud
      await syncService.performSync(userId);
      final deviceAFinalSnapshot = await syncService.buildLocalPayload(userId);

      // Verify both devices converged! Zero data lost!
      expect(deviceAFinalSnapshot.workouts.length, equals(2));
      final finalIds = deviceAFinalSnapshot.workouts.map((w) => w.id).toSet();
      expect(finalIds, containsAll(['w-devA-1', 'w-devB-2']));
    });
  });
}

class _FailingCloudBackupRepository implements CloudBackupRepository {
  @override
  Future<CloudBackupPayload?> fetchBackup(String userId) async {
    throw Exception('Network unreachable');
  }

  @override
  Future<void> saveBackup(String userId, CloudBackupPayload payload) async {
    throw Exception('Network unreachable');
  }

  @override
  Future<void> deleteBackup(String userId) async {}
}
