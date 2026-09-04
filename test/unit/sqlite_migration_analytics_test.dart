import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/storage/local_database_service.dart';
import 'package:fitora/core/health/domain/health_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for desktop/test SQLite environment
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late LocalDatabaseService dbService;

  setUp(() async {
    AppPreferences.resetForTests();
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.initialize();

    // In-memory SQLite database for clean test execution
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dbService = LocalDatabaseService(db);

    // Initialize database schema
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

  tearDown(() async {
    await db.close();
  });

  group('SQLite Database & Schema Tests', () {
    test('DailyLogRecord upsert and retrieval', () async {
      final record = DailyLogRecord(
        date: '2026-09-04',
        steps: 10500,
        caloriesBurned: 450.5,
        waterLiters: 2.5,
        sleepMinutes: 480,
        distanceKm: 7.5,
        activeMinutes: 60,
      );

      await dbService.upsertDailyLog(record);

      final fetched = await dbService.getDailyLog('2026-09-04');
      expect(fetched, isNotNull);
      expect(fetched!.date, equals('2026-09-04'));
      expect(fetched.steps, equals(10500));
      expect(fetched.caloriesBurned, equals(450.5));
      expect(fetched.waterLiters, equals(2.5));
      expect(fetched.sleepMinutes, equals(480));
      expect(fetched.distanceKm, equals(7.5));
      expect(fetched.activeMinutes, equals(60));
    });
  });

  group('Legacy SharedPreferences Migration Tests', () {
    test('migrateFromSharedPreferences successfully imports legacy records', () async {
      final prefs = AppPreferences.prefs;

      // Populate legacy SharedPreferences data
      final legacySummary = DailyActivitySummary(
        date: DateTime(2026, 9, 1),
        steps: 8000,
        stepsGoal: 10000,
        caloriesBurned: 350.0,
        caloriesGoal: 500.0,
        distanceKm: 5.5,
        activeMinutes: 45,
        activeMinutesGoal: 30,
      );
      await prefs.setString(
        'cache_daily_activity_2026_9_1',
        jsonEncode(legacySummary.toJson()),
      );

      final wellnessData = {
        'waterLogHistory': {'2026-09-01': 2.0},
        'sleepLogHistory': {'2026-09-01': 420},
      };
      await prefs.setString('fitora_wellness_state_v2', jsonEncode(wellnessData));

      // Run automatic migration
      await dbService.migrateFromSharedPreferences(prefs);

      // Verify record migrated into SQLite
      final record = await dbService.getDailyLog('2026-09-01');
      expect(record, isNotNull);
      expect(record!.steps, equals(8000));
      expect(record.caloriesBurned, equals(350.0));
      expect(record.waterLiters, equals(2.0));
      expect(record.sleepMinutes, equals(420));
      expect(record.distanceKm, equals(5.5));
      expect(record.activeMinutes, equals(45));

      // Verify migration key saved so migration runs only once
      expect(prefs.getBool('sqflite_migration_v1_completed'), isTrue);
    });
  });

  group('Historical Analytics SQL Queries (30-day, 90-day, 1-year)', () {
    test('Instant 30-day, 90-day, and 1-year historical range calculations', () async {
      final now = DateTime(2026, 9, 4);

      // Insert 100 days of daily log records into SQLite
      for (int i = 0; i < 100; i++) {
        final d = now.subtract(Duration(days: i));
        final dateStr = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        await dbService.upsertDailyLog(
          DailyLogRecord(
            date: dateStr,
            steps: 10000,
            caloriesBurned: 500.0,
            waterLiters: 2.5,
            sleepMinutes: 480,
            distanceKm: 8.0,
            activeMinutes: 60,
          ),
        );
      }

      // 30-Day Query
      final summary30 = await dbService.get30DaySummary(now);
      expect(summary30.recordCount, equals(30));
      expect(summary30.totalSteps, equals(300000));
      expect(summary30.avgSteps, equals(10000.0));
      expect(summary30.totalWaterLiters, equals(75.0));
      expect(summary30.avgSleepMinutes, equals(480.0));

      // 90-Day Query
      final summary90 = await dbService.get90DaySummary(now);
      expect(summary90.recordCount, equals(90));
      expect(summary90.totalSteps, equals(900000));
      expect(summary90.avgSteps, equals(10000.0));
      expect(summary90.totalCalories, equals(45000.0));

      // 1-Year Query (100 days populated)
      final summary1Year = await dbService.get1YearSummary(now);
      expect(summary1Year.recordCount, equals(100));
      expect(summary1Year.totalSteps, equals(1000000));
    });

    test('queryBestDayForMetric returns correct peak day', () async {
      final now = DateTime(2026, 9, 4);

      await dbService.upsertDailyLog(
        DailyLogRecord(date: '2026-09-01', steps: 5000, waterLiters: 1.5),
      );
      await dbService.upsertDailyLog(
        DailyLogRecord(date: '2026-09-02', steps: 15000, waterLiters: 3.5),
      );
      await dbService.upsertDailyLog(
        DailyLogRecord(date: '2026-09-03', steps: 8000, waterLiters: 2.0),
      );

      final bestSteps = await dbService.getBestDayForMetric(
        start: DateTime(2026, 9, 1),
        end: now,
        metricColumn: 'steps',
      );
      expect(bestSteps.key, equals('2026-09-02'));
      expect(bestSteps.value, equals(15000.0));

      final bestWater = await dbService.getBestDayForMetric(
        start: DateTime(2026, 9, 1),
        end: now,
        metricColumn: 'water_liters',
      );
      expect(bestWater.key, equals('2026-09-02'));
      expect(bestWater.value, equals(3.5));
    });
  });
}
