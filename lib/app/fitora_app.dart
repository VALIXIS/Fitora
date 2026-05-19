import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/app/providers/theme_mode_provider.dart';
import 'package:fitora/app/router/app_router.dart';
import 'package:fitora/app/theme/app_theme.dart';
import 'package:fitora/core/constants/app_constants.dart';

class FitoraApp extends ConsumerWidget {
  const FitoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
