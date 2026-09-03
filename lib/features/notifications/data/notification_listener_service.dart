// ─────────────────────────────────────────────────────
// Module   : lib/features/notifications/data/notification_listener_service.dart
// ─────────────────────────────────────────────────────

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import '../../../core/database/database_helper.dart';
import '../models/notification_model.dart';

/// Top-level callback registered for flutter_notification_listener background isolate execution.
@pragma('vm:entry-point')
void _notificationEventCallback(NotificationEvent evt) {
  // Pass to service handler
  NotificationListenerManager.handleIncomingEvent(evt);
}

/// Service managing the background notification listener lifecycle, permissions,
/// app filter validation, and SQLite persistence.
class NotificationListenerManager with ChangeNotifier {
  // Singleton pattern
  static final NotificationListenerManager instance = NotificationListenerManager._internal();
  NotificationListenerManager._internal();

  static final StreamController<NotificationModel> _notificationStreamController =
      StreamController<NotificationModel>.broadcast();

  Stream<NotificationModel> get notificationStream => _notificationStreamController.stream;

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Initialize listener service and register background handler
  Future<void> initialize() async {
    try {
      await NotificationsListener.initialize(
        callbackHandle: _notificationEventCallback,
      );
      _isListening = await NotificationsListener.isRunning ?? false;
      notifyListeners();
    } catch (e) {
      developer.log('Failed to initialize NotificationsListener: $e', name: 'NotificationListenerManager');
    }
  }

  /// Check if user has granted Notification Access permission in Android Settings
  Future<bool> hasPermission() async {
    try {
      final bool? granted = await NotificationsListener.hasPermission;
      return granted ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Open Android Notification Access Settings directly
  Future<void> requestPermission() async {
    try {
      await NotificationsListener.openPermissionSettings();
    } catch (e) {
      developer.log('Error opening permission settings: $e', name: 'NotificationListenerManager');
    }
  }

  /// Start background foreground notification listener service
  Future<bool> startListening() async {
    try {
      final hasPerm = await hasPermission();
      if (!hasPerm) {
        await requestPermission();
        return false;
      }

      await NotificationsListener.startService(
        title: "Smart Notification Tracker",
        description: "Monitoring incoming notifications in the background",
      );
      _isListening = true;
      notifyListeners();
      return true;
    } catch (e) {
      developer.log('Error starting listener service: $e', name: 'NotificationListenerManager');
      _isListening = false;
      notifyListeners();
      return false;
    }
  }

  /// Stop background notification listener service
  Future<void> stopListening() async {
    try {
      await NotificationsListener.stopService();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      developer.log('Error stopping listener service: $e', name: 'NotificationListenerManager');
    }
  }

  /// Process incoming notification event from background isolate or main thread
  /// # O(1) time, O(1) space
  static Future<void> handleIncomingEvent(NotificationEvent evt) async {
    final String packageName = evt.packageName ?? 'unknown.app';
    final String title = (evt.title ?? '').trim();
    final String body = (evt.text ?? evt.message ?? '').trim();

    // Ignore empty/system heartbeats without informative content
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    final String appName = _resolveHumanReadableAppName(packageName);
    final int timestamp = evt.createAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;

    final notification = NotificationModel(
      packageName: packageName,
      appName: appName,
      title: title.isEmpty ? appName : title,
      body: body,
      timestamp: timestamp,
    );

    // Verify filter & persist into SQLite
    final insertedId = await DatabaseHelper.instance.insertNotification(notification);

    if (insertedId != null) {
      final persistedNotification = notification.copyWith(id: insertedId);
      _notificationStreamController.add(persistedNotification);
      instance.notifyListeners();
    }
  }

  /// Resolve readable App Name from package identifier
  /// # O(1) time, O(1) space
  static String _resolveHumanReadableAppName(String packageName) {
    // Known app mappings
    final knownMappings = <String, String>{
      'com.whatsapp': 'WhatsApp',
      'com.instagram.android': 'Instagram',
      'com.facebook.katana': 'Facebook',
      'com.facebook.orca': 'Messenger',
      'com.twitter.android': 'X (Twitter)',
      'org.telegram.messenger': 'Telegram',
      'com.google.android.gm': 'Gmail',
      'com.google.android.youtube': 'YouTube',
      'com.google.android.apps.messaging': 'Google Messages',
      'com.slack': 'Slack',
      'com.discord': 'Discord',
      'com.spotify.music': 'Spotify',
      'com.linkedin.android': 'LinkedIn',
      'com.reddit.frontpage': 'Reddit',
      'com.android.vending': 'Google Play Store',
      'com.android.chrome': 'Chrome',
    };

    if (knownMappings.containsKey(packageName)) {
      return knownMappings[packageName]!;
    }

    // Heuristic: Extract and capitalize the most descriptive segment
    final parts = packageName.split('.');
    if (parts.isNotEmpty) {
      String segment = parts.last;
      if (segment.toLowerCase() == 'android' && parts.length > 1) {
        segment = parts[parts.length - 2];
      }
      return segment[0].toUpperCase() + segment.substring(1);
    }

    return packageName;
  }

  @override
  void dispose() {
    _notificationStreamController.close();
    super.dispose();
  }
}
