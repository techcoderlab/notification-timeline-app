// ─────────────────────────────────────────────────────
// Module   : test/widget_test.dart
// ─────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:notification_timeline_app/main.dart';
import 'package:notification_timeline_app/features/auth/presentation/lock_screen.dart';

void main() {
  testWidgets('SmartNotificationTrackerApp boots with LockScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartNotificationTrackerApp());

    // Verify that the LockScreen security gate is presented
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('Security Check'), findsOneWidget);
  });
}
