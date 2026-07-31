import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[Fitora] $message');
    }
  }

  static void error(Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[Fitora ERROR] $error');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
