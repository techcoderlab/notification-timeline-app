// ─────────────────────────────────────────────────────
// Module   : test/notification_model_test.dart
// ─────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:notification_timeline_app/features/notifications/models/notification_model.dart';

void main() {
  group('NotificationModel Unit Tests', () {
    test('NotificationModel serializes to and from Map accurately', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final model = NotificationModel(
        id: 1,
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        title: 'Alice',
        body: 'Hello there!',
        timestamp: now,
      );

      final map = model.toMap();
      expect(map['id'], 1);
      expect(map['package_name'], 'com.whatsapp');
      expect(map['app_name'], 'WhatsApp');
      expect(map['title'], 'Alice');
      expect(map['body'], 'Hello there!');
      expect(map['timestamp'], now);

      final reconstructed = NotificationModel.fromMap(map);
      expect(reconstructed, equals(model));
    });

    test('NotificationModel dateGroupKey identifies Today correctly', () {
      final now = DateTime.now();
      final model = NotificationModel(
        packageName: 'com.slack',
        appName: 'Slack',
        title: 'Team Update',
        body: 'Sprint planning in 10 mins',
        timestamp: now.millisecondsSinceEpoch,
      );

      expect(model.dateGroupKey, 'Today');
    });

    test('NotificationModel dateGroupKey identifies Yesterday correctly', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final model = NotificationModel(
        packageName: 'com.slack',
        appName: 'Slack',
        title: 'Standup',
        body: 'Daily update',
        timestamp: yesterday.millisecondsSinceEpoch,
      );

      expect(model.dateGroupKey, 'Yesterday');
    });

    test('AppFilterModel serializes to and from Map correctly', () {
      const filter = AppFilterModel(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        isEnabled: true,
      );

      final map = filter.toMap();
      expect(map['package_name'], 'com.instagram.android');
      expect(map['app_name'], 'Instagram');
      expect(map['is_enabled'], 1);

      final reconstructed = AppFilterModel.fromMap(map);
      expect(reconstructed.packageName, 'com.instagram.android');
      expect(reconstructed.appName, 'Instagram');
      expect(reconstructed.isEnabled, true);
    });
  });
}
