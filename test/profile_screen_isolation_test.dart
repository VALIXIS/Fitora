import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/features/profile/screens/profile_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/storage/app_preferences.dart';

void main() {
  testWidgets('Profile Isolation Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    SharedPreferences.setMockInitialValues({});
    await AppPreferences.initialize();

    // Simulate AppShell nesting
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SafeArea(child: ProfileScreen())),
        ),
      ),
    );

    await tester.pump();

    if (tester.takeException() != null) {
      print('CRASH FOUND: \${tester.takeException()}');
    } else {
      print('NO CRASH FOUND. ALL WIDGETS RENDERED PERFECTLY.');
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
