import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    debugPrint('[Fitora] $message');
  }

  static void error(Object error, [StackTrace? stackTrace]) {
    debugPrint('[Fitora ERROR] $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
