import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/app/providers/theme_mode_provider.dart';
import 'package:fitora/app/router/app_router.dart';
import 'package:fitora/app/theme/app_theme.dart';
import 'package:fitora/core/constants/app_constants.dart';
import 'package:fitora/core/services/notification_service.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/sleep/widgets/log_sleep_modal.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class FitoraApp extends ConsumerStatefulWidget {
  const FitoraApp({super.key});

  @override
  ConsumerState<FitoraApp> createState() => _FitoraAppState();
}

class _FitoraAppState extends ConsumerState<FitoraApp> {
  StreamSubscription<String>? _actionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _setupNotificationActionListener();
    });
  }

  void _setupNotificationActionListener() {
    final notificationSvc = NotificationService();
    _actionSubscription = notificationSvc.onNotificationAction.listen((actionId) {
      _handleAction(actionId);
    });
    notificationSvc.checkAppLaunchNotification();
  }

  void _handleAction(String actionId) {
    if (actionId == NotificationService.actionAddWater250) {
      ref.read(wellnessProvider.notifier).addHydration(0.25);
    } else if (actionId == NotificationService.actionLogSleep) {
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        showSleepLogModal(context, ref);
      }
    }
  }

  @override
  void dispose() {
    _actionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
