import 'package:flutter_test/flutter_test.dart';
import 'package:fitora/core/utils/greeting_utils.dart';

void main() {
  group('getDynamicGreeting', () {
    test('returns "Good Morning" between 05:00 and 11:59', () {
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 5, 0)),
        equals('Good Morning'),
      );
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 8, 30)),
        equals('Good Morning'),
      );
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 11, 59)),
        equals('Good Morning'),
      );
    });

    test('returns "Good Afternoon" between 12:00 and 16:59', () {
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 12, 0)),
        equals('Good Afternoon'),
      );
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 14, 15)),
        equals('Good Afternoon'),
      );
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 16, 59)),
        equals('Good Afternoon'),
      );
    });

    test('returns "Good Evening" between 17:00 and 21:59', () {
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 17, 0)),
        equals('Good Evening'),
      );
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 19, 45)),
        equals('Good Evening'),
      );
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 21, 59)),
        equals('Good Evening'),
      );
    });

    test('returns "Good Night" between 22:00 and 04:59', () {
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 22, 0)),
        equals('Good Night'),
      );
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 23, 59)),
        equals('Good Night'),
      );
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 0, 0)),
        equals('Good Night'),
      );
      expect(
        getDynamicGreeting(DateTime(2026, 8, 9, 4, 59)),
        equals('Good Night'),
      );
    });
  });
}
