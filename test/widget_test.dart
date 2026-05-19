// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/app/fitora_app.dart';
import 'package:fitora/core/constants/app_constants.dart';
import 'package:fitora/core/storage/app_preferences.dart';

void main() {
  testWidgets('Fitora shows splash content', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.initialize();
    await tester.pumpWidget(const ProviderScope(child: FitoraApp()));
    expect(find.text(AppConstants.appName), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
