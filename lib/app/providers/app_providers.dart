import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/utils/app_logger.dart';

const List<Override> appProviderOverrides = [];

final List<ProviderObserver> appProviderObservers = [
  AppProviderObserver(),
];

class AppProviderObserver extends ProviderObserver {

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      final name = provider.name ?? provider.runtimeType.toString();
      AppLogger.info('Provider updated: $name');
    }
  }
}
