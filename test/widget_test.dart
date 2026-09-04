// ─────────────────────────────────────────────────────
// Module   : test/widget_test.dart
// ─────────────────────────────────────────────────────

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_timeline_app/main.dart';
import 'package:notification_timeline_app/features/auth/presentation/lock_screen.dart';
import 'package:notification_timeline_app/features/notifications/presentation/timeline_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // 1. Mock sqflite platform channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.tekartik.sqflite'), (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getDatabasesPath':
          return '/mock/databases';
        case 'openDatabase':
          return 1;
        case 'execute':
          return null;
        case 'query':
          return <Map<String, Object?>>[];
        case 'insert':
          return 1;
        case 'update':
          return 1;
        case 'delete':
          return 0;
        case 'closeDatabase':
          return null;
        case 'batch':
          return <dynamic>[];
        default:
          return null;
      }
    });

    // 2. Mock flutter_secure_storage platform channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'read':
          return null;
        case 'write':
          return null;
        case 'delete':
          return null;
        case 'deleteAll':
          return null;
        case 'readAll':
          return <String, String>{};
        case 'containsKey':
          return false;
        default:
          return null;
      }
    });

    // 3. Mock local_auth platform channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/local_auth'), (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'isDeviceSupported':
          return false;
        case 'canCheckBiometrics':
          return false;
        case 'getAvailableBiometrics':
          return <String>[];
        case 'authenticate':
          return false;
        default:
          return null;
      }
    });

    // 4. Mock flutter_notification_listener platform channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_notification_listener'), (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'plugin.initialize':
          return true;
        case 'plugin.hasPermission':
          return false;
        case 'plugin.openPermissionSettings':
          return null;
        case 'plugin.isRunning':
          return false;
        case 'plugin.startService':
          return true;
        case 'plugin.stopService':
          return true;
        default:
          return null;
      }
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_notification_listener/method'), (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'plugin.initialize':
          return true;
        case 'plugin.hasPermission':
          return false;
        case 'plugin.openPermissionSettings':
          return null;
        case 'plugin.isServiceRunning':
          return false;
        case 'plugin.startService':
          return true;
        case 'plugin.stopService':
          return true;
        default:
          return null;
      }
    });

    // 5. Mock Android native host channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.example.notification_timeline_app/installed_apps'), (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getInstalledApps':
          return <Map<String, dynamic>>[];
        case 'checkNotificationPermission':
          return false;
        case 'openNotificationListenerSettings':
          return true;
        case 'rebindNotificationListener':
          return true;
        case 'startNotificationListenerService':
          return true;
        case 'requestPostNotificationPermission':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.tekartik.sqflite'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/local_auth'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_notification_listener'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_notification_listener/method'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.example.notification_timeline_app/installed_apps'), null);
  });

  testWidgets('SmartNotificationTrackerApp boots with LockScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartNotificationTrackerApp());
    await tester.pumpAndSettle();

    // Verify that the LockScreen security gate is presented
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('Security Check'), findsOneWidget);
    expect(find.text('Enter your 6-digit passcode'), findsOneWidget);
  });

  testWidgets('LockScreen rejects invalid PIN and resets with error', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartNotificationTrackerApp());
    await tester.pumpAndSettle();

    // Tap 6 digits: 9 9 9 9 9 9
    for (int i = 0; i < 6; i++) {
      await tester.tap(find.text('9'));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    // Verify error message is shown
    expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);
  });

  testWidgets('LockScreen unlocks to TimelineScreen with default PIN 123456', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartNotificationTrackerApp());
    await tester.pumpAndSettle();

    // Enter default PIN: 1 2 3 4 5 6
    const pin = ['1', '2', '3', '4', '5', '6'];
    for (final digit in pin) {
      await tester.tap(find.text(digit));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Use pump() with fixed duration instead of pumpAndSettle() because
    // TimelineScreen has a live broadcast StreamSubscription listener that
    // never completes, causing pumpAndSettle() to time out indefinitely.
    await tester.pump(const Duration(seconds: 2));

    // Verify successful navigation to TimelineScreen
    expect(find.byType(TimelineScreen), findsOneWidget);
  });
}
