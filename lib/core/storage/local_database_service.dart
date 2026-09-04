import 'dart:convert';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/utils/app_logger.dart';

/// Data class representing a daily log row in SQLite.
class DailyLogRecord {
  final String date; // YYYY-MM-DD
  final int steps;
  final double caloriesBurned;
  final double waterLiters;
  final int sleepMinutes;
  final double distanceKm;
  final int activeMinutes;
  final DateTime updatedAt;

  DailyLogRecord({
    required this.date,
    this.steps = 0,
    this.caloriesBurned = 0.0,
    this.waterLiters = 0.0,
    this.sleepMinutes = 0,
    this.distanceKm = 0.0,
    this.activeMinutes = 0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'steps': steps,
      'calories_burned': caloriesBurned,
      'water_liters': waterLiters,
      'sleep_minutes': sleepMinutes,
      'distance_km': distanceKm,
      'active_minutes': activeMinutes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DailyLogRecord.fromMap(Map<String, dynamic> map) {
    return DailyLogRecord(
      date: map['date'] as String,
      steps: (map['steps'] as num?)?.toInt() ?? 0,
      caloriesBurned: (map['calories_burned'] as num?)?.toDouble() ?? 0.0,
      waterLiters: (map['water_liters'] as num?)?.toDouble() ?? 0.0,
      sleepMinutes: (map['sleep_minutes'] as num?)?.toInt() ?? 0,
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0.0,
      activeMinutes: (map['active_minutes'] as num?)?.toInt() ?? 0,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  DailyLogRecord copyWith({
    String? date,
    int? steps,
    double? caloriesBurned,
    double? waterLiters,
    int? sleepMinutes,
    double? distanceKm,
    int? activeMinutes,
    DateTime? updatedAt,
  }) {
    return DailyLogRecord(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      waterLiters: waterLiters ?? this.waterLiters,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Query summary result containing aggregated metrics computed directly by SQLite engine.
class HistoricalQuerySummary {
  final int recordCount;
  final int totalSteps;
  final double avgSteps;
  final double totalCalories;
  final double avgCalories;
  final double totalWaterLiters;
  final double avgWaterLiters;
  final int totalSleepMinutes;
  final double avgSleepMinutes;
  final double totalDistanceKm;
  final double avgDistanceKm;
  final int totalActiveMinutes;
  final double avgActiveMinutes;

  HistoricalQuerySummary({
    required this.recordCount,
    required this.totalSteps,
    required this.avgSteps,
    required this.totalCalories,
    required this.avgCalories,
    required this.totalWaterLiters,
    required this.avgWaterLiters,
    required this.totalSleepMinutes,
    required this.avgSleepMinutes,
    required this.totalDistanceKm,
    required this.avgDistanceKm,
    required this.totalActiveMinutes,
    required this.avgActiveMinutes,
  });

  factory HistoricalQuerySummary.empty() {
    return HistoricalQuerySummary(
      recordCount: 0,
      totalSteps: 0,
      avgSteps: 0.0,
      totalCalories: 0.0,
      avgCalories: 0.0,
      totalWaterLiters: 0.0,
      avgWaterLiters: 0.0,
      totalSleepMinutes: 0,
      avgSleepMinutes: 0.0,
      totalDistanceKm: 0.0,
      avgDistanceKm: 0.0,
      totalActiveMinutes: 0,
      avgActiveMinutes: 0.0,
    );
  }
}

/// Service managing SQLite database initialization, automatic schema migrations,
/// legacy SharedPreferences data migration, and high-performance SQL analytics queries.
class LocalDatabaseService {
  static const String _dbName = 'fitora_health_logs.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'daily_logs';
  static const String _migrationCompletedKey = 'sqflite_migration_v1_completed';

  Database? _db;
  final DatabaseExecutor? _customExecutor; // For FFI unit testing injection

  LocalDatabaseService([this._customExecutor]);

  /// Returns active Database connection.
  Future<DatabaseExecutor> get database async {
    final exec = _customExecutor;
    if (exec != null) return exec;
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('Creating SQLite daily_logs table (schema v$version)...');
    await db.execute('''
      CREATE TABLE $_tableName (
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_logs_date ON $_tableName(date);');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('Upgrading SQLite schema from v$oldVersion to v$newVersion...');
    // Schema upgrade hooks for future version increments
  }

  // ---------------------------------------------------------------------------
  // Legacy SharedPreferences Automatic Migration
  // ---------------------------------------------------------------------------

  /// Automatically reads legacy SharedPreferences keys and migrates daily activity,
  /// sleep summaries, and water log history into SQLite `daily_logs` table.
  Future<void> migrateFromSharedPreferences(SharedPreferences prefs) async {
    final alreadyMigrated = prefs.getBool(_migrationCompletedKey) ?? false;
    if (alreadyMigrated) return;

    try {
      AppLogger.info('Starting automatic SharedPreferences to SQLite migration...');
      final db = await database;
      final Map<String, DailyLogRecord> recordsToMigrate = {};

      // 1. Scan legacy cache_daily_activity_* keys
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_daily_activity_')) {
          final jsonStr = prefs.getString(key);
          if (jsonStr != null) {
            try {
              final summary = DailyActivitySummary.fromJson(jsonDecode(jsonStr));
              final dateStr = _formatDate(summary.date);
              final existing = recordsToMigrate[dateStr] ?? DailyLogRecord(date: dateStr);
              recordsToMigrate[dateStr] = existing.copyWith(
                steps: summary.steps,
                caloriesBurned: summary.caloriesBurned,
                distanceKm: summary.distanceKm,
                activeMinutes: summary.activeMinutes,
              );
            } catch (_) {}
          }
        } else if (key.startsWith('cache_sleep_summary_')) {
          final jsonStr = prefs.getString(key);
          if (jsonStr != null) {
            try {
              final sleepJson = jsonDecode(jsonStr) as Map<String, dynamic>;
              final dateRaw = sleepJson['date'] as String?;
              if (dateRaw != null) {
                final dateStr = _formatDate(DateTime.parse(dateRaw));
                final sleepMins = (sleepJson['totalSleepMinutes'] as num?)?.toInt() ?? 0;
                final existing = recordsToMigrate[dateStr] ?? DailyLogRecord(date: dateStr);
                recordsToMigrate[dateStr] = existing.copyWith(
                  sleepMinutes: sleepMins > 0 ? sleepMins : existing.sleepMinutes,
                );
              }
            } catch (_) {}
          }
        }
      }

      // 2. Scan fitora_wellness_state_v2 for waterLogHistory & sleepLogHistory
      final wellnessRaw = prefs.getString('fitora_wellness_state_v2');
      if (wellnessRaw != null) {
        try {
          final map = jsonDecode(wellnessRaw) as Map<String, dynamic>;
          final waterHistory = map['waterLogHistory'] as Map<String, dynamic>?;
          if (waterHistory != null) {
            waterHistory.forEach((dateStr, val) {
              final waterVal = (val as num).toDouble();
              final existing = recordsToMigrate[dateStr] ?? DailyLogRecord(date: dateStr);
              recordsToMigrate[dateStr] = existing.copyWith(waterLiters: waterVal);
            });
          }
          final sleepHistory = map['sleepLogHistory'] as Map<String, dynamic>?;
          if (sleepHistory != null) {
            sleepHistory.forEach((dateStr, val) {
              final sleepMins = (val as num).toInt();
              final existing = recordsToMigrate[dateStr] ?? DailyLogRecord(date: dateStr);
              recordsToMigrate[dateStr] = existing.copyWith(sleepMinutes: sleepMins);
            });
          }
        } catch (_) {}
      }

      // 3. Batch insert records into SQLite
      if (recordsToMigrate.isNotEmpty) {
        if (db is Database) {
          final batch = db.batch();
          for (final record in recordsToMigrate.values) {
            batch.insert(
              _tableName,
              record.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        } else {
          for (final record in recordsToMigrate.values) {
            await db.insert(
              _tableName,
              record.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        AppLogger.info('Migrated ${recordsToMigrate.length} legacy records to SQLite.');
      }

      await prefs.setBool(_migrationCompletedKey, true);
    } catch (e, st) {
      AppLogger.error('SQLite migration from SharedPreferences failed: $e', st);
    }
  }

  // ---------------------------------------------------------------------------
  // CRUD Operations
  // ---------------------------------------------------------------------------

  /// Atomically inserts or updates a daily log record.
  Future<void> upsertDailyLog(DailyLogRecord record) async {
    try {
      final db = await database;
      final existing = await getDailyLog(record.date);

      final mergedRecord = DailyLogRecord(
        date: record.date,
        steps: record.steps > 0 ? record.steps : (existing?.steps ?? 0),
        caloriesBurned: record.caloriesBurned > 0.0 ? record.caloriesBurned : (existing?.caloriesBurned ?? 0.0),
        waterLiters: record.waterLiters > 0.0 ? record.waterLiters : (existing?.waterLiters ?? 0.0),
        sleepMinutes: record.sleepMinutes > 0 ? record.sleepMinutes : (existing?.sleepMinutes ?? 0),
        distanceKm: record.distanceKm > 0.0 ? record.distanceKm : (existing?.distanceKm ?? 0.0),
        activeMinutes: record.activeMinutes > 0 ? record.activeMinutes : (existing?.activeMinutes ?? 0),
        updatedAt: DateTime.now(),
      );

      await db.insert(
        _tableName,
        mergedRecord.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      AppLogger.error('upsertDailyLog error: $e', st);
    }
  }

  /// Fetches a daily log record for a single date (YYYY-MM-DD).
  Future<DailyLogRecord?> getDailyLog(String dateStr) async {
    try {
      final db = await database;
      final results = await db.query(
        _tableName,
        where: 'date = ?',
        whereArgs: [dateStr],
        limit: 1,
      );
      if (results.isNotEmpty) {
        return DailyLogRecord.fromMap(results.first);
      }
    } catch (e, st) {
      AppLogger.error('getDailyLog error: $e', st);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // High-Performance Historical SQL Queries (30-day, 90-day, 1-year analytics)
  // ---------------------------------------------------------------------------

  /// Calculates aggregated totals and averages directly via SQLite engine
  /// for any arbitrary date range without loading large lists into RAM.
  Future<HistoricalQuerySummary> queryHistoricalRangeSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final db = await database;
      final startStr = _formatDate(start);
      final endStr = _formatDate(end);

      final results = await db.rawQuery('''
        SELECT 
          COUNT(*) as record_count,
          COALESCE(SUM(steps), 0) as total_steps,
          COALESCE(AVG(steps), 0.0) as avg_steps,
          COALESCE(SUM(calories_burned), 0.0) as total_calories,
          COALESCE(AVG(calories_burned), 0.0) as avg_calories,
          COALESCE(SUM(water_liters), 0.0) as total_water,
          COALESCE(AVG(water_liters), 0.0) as avg_water,
          COALESCE(SUM(sleep_minutes), 0) as total_sleep,
          COALESCE(AVG(sleep_minutes), 0.0) as avg_sleep,
          COALESCE(SUM(distance_km), 0.0) as total_distance,
          COALESCE(AVG(distance_km), 0.0) as avg_distance,
          COALESCE(SUM(active_minutes), 0) as total_active,
          COALESCE(AVG(active_minutes), 0.0) as avg_active
        FROM $_tableName
        WHERE date >= ? AND date <= ?
      ''', [startStr, endStr]);

      if (results.isNotEmpty) {
        final row = results.first;
        return HistoricalQuerySummary(
          recordCount: (row['record_count'] as num?)?.toInt() ?? 0,
          totalSteps: (row['total_steps'] as num?)?.toInt() ?? 0,
          avgSteps: (row['avg_steps'] as num?)?.toDouble() ?? 0.0,
          totalCalories: (row['total_calories'] as num?)?.toDouble() ?? 0.0,
          avgCalories: (row['avg_calories'] as num?)?.toDouble() ?? 0.0,
          totalWaterLiters: (row['total_water'] as num?)?.toDouble() ?? 0.0,
          avgWaterLiters: (row['avg_water'] as num?)?.toDouble() ?? 0.0,
          totalSleepMinutes: (row['total_sleep'] as num?)?.toInt() ?? 0,
          avgSleepMinutes: (row['avg_sleep'] as num?)?.toDouble() ?? 0.0,
          totalDistanceKm: (row['total_distance'] as num?)?.toDouble() ?? 0.0,
          avgDistanceKm: (row['avg_distance'] as num?)?.toDouble() ?? 0.0,
          totalActiveMinutes: (row['total_active'] as num?)?.toInt() ?? 0,
          avgActiveMinutes: (row['avg_active'] as num?)?.toDouble() ?? 0.0,
        );
      }
    } catch (e, st) {
      AppLogger.error('queryHistoricalRangeSummary error: $e', st);
    }
    return HistoricalQuerySummary.empty();
  }

  /// Instant 30-day historical analytics query.
  Future<HistoricalQuerySummary> get30DaySummary([DateTime? endDate]) {
    final end = endDate ?? DateTime.now();
    final start = end.subtract(const Duration(days: 29));
    return queryHistoricalRangeSummary(start: start, end: end);
  }

  /// Instant 90-day historical analytics query.
  Future<HistoricalQuerySummary> get90DaySummary([DateTime? endDate]) {
    final end = endDate ?? DateTime.now();
    final start = end.subtract(const Duration(days: 89));
    return queryHistoricalRangeSummary(start: start, end: end);
  }

  /// Instant 1-year historical analytics query.
  Future<HistoricalQuerySummary> get1YearSummary([DateTime? endDate]) {
    final end = endDate ?? DateTime.now();
    final start = end.subtract(const Duration(days: 364));
    return queryHistoricalRangeSummary(start: start, end: end);
  }

  /// Query best day for steps or water intake using SQL ORDER BY DESC.
  Future<MapEntry<String, double>> getBestDayForMetric({
    required DateTime start,
    required DateTime end,
    required String metricColumn,
  }) async {
    try {
      final db = await database;
      final startStr = _formatDate(start);
      final endStr = _formatDate(end);

      final results = await db.query(
        _tableName,
        columns: ['date', metricColumn],
        where: 'date >= ? AND date <= ?',
        whereArgs: [startStr, endStr],
        orderBy: '$metricColumn DESC',
        limit: 1,
      );

      if (results.isNotEmpty) {
        final row = results.first;
        final dateStr = row['date'] as String;
        final val = (row[metricColumn] as num?)?.toDouble() ?? 0.0;
        return MapEntry(dateStr, val);
      }
    } catch (e, st) {
      AppLogger.error('getBestDayForMetric error: $e', st);
    }
    return const MapEntry('N/A', 0.0);
  }

  static String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
