import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/app/fitora_app.dart';
import 'package:fitora/app/providers/app_providers.dart';
import 'package:fitora/core/services/app_initializer.dart';
import 'package:fitora/core/utils/app_logger.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

class AppBootstrap {
  static Future<void> run() async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('AppBootstrap: Starting initialization...');

    await runZonedGuarded(
      () async {
        final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
        AppLogger.info('AppBootstrap: WidgetsFlutterBinding initialized at ${stopwatch.elapsedMilliseconds}ms');
        
        FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          if (details.stack != null) {
            AppLogger.error(details.exception, details.stack!);
          }
        };

        await AppInitializer.initialize();
        AppLogger.info('AppBootstrap: AppInitializer completed at ${stopwatch.elapsedMilliseconds}ms');
        
        runApp(
          ProviderScope(
            observers: appProviderObservers,
            overrides: appProviderOverrides,
            child: const FitoraApp(),
          ),
        );
        AppLogger.info('AppBootstrap: runApp called at ${stopwatch.elapsedMilliseconds}ms');
      },
      (error, stackTrace) {
        AppLogger.error(error, stackTrace);
      },
    );
  }
}
