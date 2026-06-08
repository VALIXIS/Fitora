import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/app/fitora_app.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('FitoraApp launches successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.initialize();
    await tester.pumpWidget(const ProviderScope(child: FitoraApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
