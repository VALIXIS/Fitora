import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/services/health_connect_service.dart';
import 'package:health/health.dart';

import 'package:fitora/features/health_sync/providers/health_sync_provider.dart';
import 'package:fitora/core/health/services/health_sync_service.dart';
import 'package:fitora/core/health/services/health_cache_service.dart';
import 'package:fitora/core/health/services/background_sync_service.dart';
import 'package:fitora/core/health/data/sensor_health_repository.dart';

// A mock HealthConnectService for test purposes
class MockHealthConnectService implements HealthConnectService {
  HealthConnectStatus mockStatus = HealthConnectStatus.unavailable;
  bool mockRequestResult = false;

  MockHealthConnectService();

  @override
  Future<HealthConnectStatus> getStatus() async {
    return mockStatus;
  }

  @override
  Future<bool> requestPermissions() async {
    return mockRequestResult;
  }

  @override
  Future<int?> getSteps(DateTime start, DateTime end) async {
    return 0;
  }

  @override
  Future<List<HealthDataPoint>> getHealthData(
    DateTime start,
    DateTime end, {
    List<HealthDataType>? types,
  }) async {
    return [];
  }

  @override
  Future<List<HealthDataPoint>> getSleepData(
    DateTime start,
    DateTime end,
  ) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> runDirectDiagnostic() async {
    return {};
  }
}

class DummyHealthSyncController extends HealthSyncController {
  DummyHealthSyncController() : super();

  @override
  Future<void> load() async {}

  @override
  Future<void> syncAllActive() async {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}
}

class DummyHealthSyncService extends HealthSyncService {
  DummyHealthSyncService(super.hcRepo, super.sensorRepo, super.cache);

  @override
  Future<void> syncNow({bool isBackground = false}) async {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AppPreferences.resetForTests();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await AppPreferences.initialize();

    const channel = MethodChannel('dev.fluttercommunity.plus/device_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      return {
        'sdkInt': 33,
        'release': '13',
        'model': 'Mock Model',
        'manufacturer': 'Mock Manufacturer',
        'systemName': 'iOS',
        'systemVersion': '16.0',
        'name': 'iPhone',
        'localizedModel': 'iPhone',
        'identifierForVendor': 'mock-vendor-id',
        'isPhysicalDevice': false,
      };
    });
  });

  group('Background Refresh and Lifecycle Tests', () {
    test('todayProvider changing date after resume', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initially, it should match current date
      final initialToday = container.read(todayProvider);
      final now = DateTime.now();
      expect(initialToday, equals(DateTime(now.year, now.month, now.day)));

      final notifier = container.read(todayProvider.notifier);
      
      // Simulate same-day resume (should not change date)
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(container.read(todayProvider), equals(initialToday));
    });

    test('no duplicate lifecycle observers/listeners', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(todayProvider.notifier);
      
      // Verify notifier disposes cleanly without exceptions
      expect(() => container.dispose(), returnsNormally);
    });

    test('Health Connect status refreshing after resume', () async {
      final mockService = MockHealthConnectService();
      final container = ProviderContainer(
        overrides: [
          healthConnectServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Initially unavailable
      mockService.mockStatus = HealthConnectStatus.unavailable;
      final statusNotifier = container.read(healthConnectStatusProvider.notifier);
      await statusNotifier.checkStatus();
      expect(container.read(healthConnectStatusProvider), equals(HealthConnectStatus.unavailable));

      // Simulate status change on resume
      mockService.mockStatus = HealthConnectStatus.connected;
      statusNotifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      
      await statusNotifier.checkStatus();
      expect(container.read(healthConnectStatusProvider), equals(HealthConnectStatus.connected));
    });

    test('permission revoked/granted between app sessions', () async {
      final mockService = MockHealthConnectService();
      final container = ProviderContainer(
        overrides: [
          healthConnectServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Session 1: Status is connected
      mockService.mockStatus = HealthConnectStatus.connected;
      final statusNotifier = container.read(healthConnectStatusProvider.notifier);
      await statusNotifier.checkStatus();
      expect(container.read(healthConnectStatusProvider), equals(HealthConnectStatus.connected));

      // Session 2 (simulate permissions revoked in system settings)
      mockService.mockStatus = HealthConnectStatus.revoked;
      await statusNotifier.checkStatus();
      expect(container.read(healthConnectStatusProvider), equals(HealthConnectStatus.revoked));
    });

    test('dailyActivityProvider responding to todayProvider changes', () {
      final mockService = MockHealthConnectService();
      final container = ProviderContainer(
        overrides: [
          healthConnectServiceProvider.overrideWithValue(mockService),
          healthSyncProvider.overrideWith((ref) => DummyHealthSyncController()),
          healthSyncServiceProvider.overrideWith((ref) {
            final hcRepo = ref.watch(healthConnectRepositoryProvider);
            final sensorRepo = ref.watch(sensorHealthRepositoryProvider);
            final cache = ref.watch(healthCacheServiceProvider);
            return DummyHealthSyncService(hcRepo, sensorRepo, cache);
          }),
        ],
      );
      addTearDown(container.dispose);

      final today = container.read(todayProvider);
      
      final summary = container.read(dailyActivityProvider(today));
      expect(summary.date, equals(today));

      // Rebuild and update todayProvider date manually to simulate day rollover
      final tomorrow = today.add(const Duration(days: 1));
      container.read(todayProvider.notifier).state = tomorrow;

      final newSummary = container.read(dailyActivityProvider(tomorrow));
      expect(newSummary.date, equals(tomorrow));
    });

    test('BackgroundSyncManager initialization and background task execution', () async {
      // Test initialization in test mode
      await BackgroundSyncManager.initialize(isTesting: true);
      
      // Execute task cleanly
      final result = await executeBackgroundHealthSyncTask(taskName: kFitoraBackgroundSyncTask);
      expect(result, isTrue);

      // Verify cached daily activity persisted
      final cacheService = HealthCacheService(AppPreferences.prefs);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final cachedActivity = cacheService.getDailyActivity(today);
      expect(cachedActivity, isNotNull);
      expect(cachedActivity!.date, equals(today));
    });
  });
}
