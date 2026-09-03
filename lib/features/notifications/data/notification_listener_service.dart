// ─────────────────────────────────────────────────────
// Module   : lib/features/notifications/data/notification_listener_service.dart
// ─────────────────────────────────────────────────────

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/security/secure_storage.dart';
import '../models/notification_model.dart';

/// Top-level callback registered for flutter_notification_listener background isolate execution.
@pragma('vm:entry-point')
void _notificationEventCallback(NotificationEvent evt) {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationListenerManager.handleIncomingEvent(evt);
}

/// Service managing the notification listener lifecycle, permissions,
/// app filter validation, and SQLite persistence.
class NotificationListenerManager with ChangeNotifier {
  static final NotificationListenerManager instance = NotificationListenerManager._internal();
  NotificationListenerManager._internal();

  static final StreamController<NotificationModel> _notificationStreamController =
      StreamController<NotificationModel>.broadcast();

  Stream<NotificationModel> get notificationStream => _notificationStreamController.stream;

  bool _isListening = true;
  bool get isListening => _isListening;

  /// Initialize listener service and register background handler
  Future<void> initialize() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _isListening = await SecureStorageService.instance.isTrackingEnabled();

      await NotificationsListener.initialize(
        callbackHandle: _notificationEventCallback,
      );
      notifyListeners();
    } catch (e) {
      developer.log('Initialization notice for NotificationsListener: $e', name: 'NotificationListenerManager');
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

  /// Toggle notification tracking master switch
  Future<bool> toggleTracking(bool enable) async {
    try {
      await SecureStorageService.instance.setTrackingEnabled(enable);
      _isListening = enable;
      notifyListeners();
      return true;
    } catch (e) {
      developer.log('Error toggling tracking: $e', name: 'NotificationListenerManager');
      return false;
    }
  }

  /// Start background notification tracking
  Future<bool> startListening() async {
    return await toggleTracking(true);
  }

  /// Stop background notification tracking
  Future<void> stopListening() async {
    await toggleTracking(false);
  }

  /// Process incoming notification event safely from background isolate or main thread
  /// # O(1) time, O(1) space
  static Future<void> handleIncomingEvent(NotificationEvent evt) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // Check master tracking switch
      final isEnabled = await SecureStorageService.instance.isTrackingEnabled();
      if (!isEnabled) {
        return;
      }

      final String packageName = evt.packageName ?? 'unknown.app';
      final String title = (evt.title ?? '').trim();
      final String body = (evt.text ?? evt.message ?? '').trim();

      // Ignore empty or system ping events
      if (title.isEmpty && body.isEmpty) {
        return;
      }

      // Verify if app is allowed by user filter rules
      final isAllowed = await DatabaseHelper.instance.isAppAllowed(packageName);
      if (!isAllowed) {
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

      final insertedId = await DatabaseHelper.instance.insertNotification(notification);

      if (insertedId != null) {
        final persistedNotification = notification.copyWith(id: insertedId);
        _notificationStreamController.add(persistedNotification);
        instance.notifyListeners();
      }
    } catch (e) {
      developer.log('Error in notification event handler: $e', name: 'NotificationListenerManager');
    }
  }

  /// Resolve readable App Name from package identifier
  /// # O(1) time, O(1) space
  static String _resolveHumanReadableAppName(String packageName) {
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

    // Extract and format last meaningful identifier
    final parts = packageName.split('.');
    if (parts.isNotEmpty) {
      String segment = parts.last;
      if (segment.toLowerCase() == 'android' && parts.length > 1) {
        segment = parts[parts.length - 2];
      }
      if (segment.isNotEmpty) {
        return segment[0].toUpperCase() + segment.substring(1);
      }
    }

    return packageName;
  }

  @override
  void dispose() {
    _notificationStreamController.close();
    super.dispose();
  }
}
