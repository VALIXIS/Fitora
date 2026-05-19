import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/app/fitora_app.dart';
import 'package:fitora/app/providers/app_providers.dart';
import 'package:fitora/core/services/app_initializer.dart';
import 'package:fitora/core/utils/app_logger.dart';

class AppBootstrap {
  static Future<void> run() async {
    await runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          if (details.stack != null) {
            AppLogger.error(details.exception, details.stack!);
          }
        };

        await AppInitializer.initialize();
        runApp(
          ProviderScope(
            observers: appProviderObservers,
            overrides: appProviderOverrides,
            child: const FitoraApp(),
          ),
        );
      },
      (error, stackTrace) {
        AppLogger.error(error, stackTrace);
      },
    );
  }
}
