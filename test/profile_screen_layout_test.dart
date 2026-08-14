import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/features/profile/screens/profile_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/storage/app_preferences.dart';

void main() {
  testWidgets('ProfileScreen Layout Test', (WidgetTester tester) async {
    // Provide a large enough surface to simulate a device screen
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    SharedPreferences.setMockInitialValues({});
    await AppPreferences.initialize();

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileScreen())),
    );

    // Wait for layout
    await tester.pump();

    // Check for layout exceptions
    expect(tester.takeException(), isNull);

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
