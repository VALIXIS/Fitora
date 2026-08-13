import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF0E1312),
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ));

        FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          if (details.stack != null) {
            AppLogger.error(details.exception, details.stack!);
          }
        };

        try {
          await AppInitializer.initialize().timeout(const Duration(seconds: 4));
          AppLogger.info('AppBootstrap: AppInitializer completed at ${stopwatch.elapsedMilliseconds}ms');
        } catch (error, stackTrace) {
          AppLogger.error('AppInitializer error or timeout: $error', stackTrace);
        }
        
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
