import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/features/health_sync/screens/health_sync_screen.dart';

void main() {
  testWidgets('HealthSyncScreen renders without crashes', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.initialize();
    
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HealthSyncScreen(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    expect(find.byType(HealthSyncScreen), findsOneWidget);

    print('[HC_DIAG] Printing all rendered Text widgets on HealthSyncScreen:');
    for (final element in tester.allElements) {
      if (element.widget is Text) {
        print('  - Text: ${(element.widget as Text).data}');
      }
    }
  });
}
