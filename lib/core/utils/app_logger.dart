import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    debugPrint('[Fitora] $message');
  }

  static void error(Object error, StackTrace stackTrace) {
    debugPrint('[Fitora] $error');
    debugPrint(stackTrace.toString());
  }
}
