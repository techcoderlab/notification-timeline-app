// ─────────────────────────────────────────────────────
// Module   : lib/features/notifications/data/notification_listener_service.dart
// ─────────────────────────────────────────────────────

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/security/secure_storage.dart';
import '../models/notification_model.dart';

/// Top-level callback registered for flutter_notification_listener background isolate execution.
@pragma('vm:entry-point')
void _notificationEventCallback(NotificationEvent evt) async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationListenerManager.persistIncomingEvent(evt);

  // Send to custom listener port
  final SendPort? sendCustom = IsolateNameServer.lookupPortByName("_listener_");
  sendCustom?.send(evt);

  // Send to plugin standard port
  final SendPort? sendPlugin =
      IsolateNameServer.lookupPortByName(NotificationsListener.SEND_PORT_NAME);
  sendPlugin?.send(evt);
}

/// Service managing the notification listener lifecycle, permissions,
/// app filter validation, and SQLite persistence.
class NotificationListenerManager with ChangeNotifier {
  static final NotificationListenerManager instance =
      NotificationListenerManager._internal();
  NotificationListenerManager._internal();

  static const MethodChannel _nativeHostChannel =
      MethodChannel('com.example.notification_timeline_app/installed_apps');

  static final ReceivePort _uiReceivePort = ReceivePort();

  static final StreamController<NotificationModel> _notificationStreamController =
      StreamController<NotificationModel>.broadcast();

  Stream<NotificationModel> get notificationStream =>
      _notificationStreamController.stream;

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

      // Register UI receive port
      IsolateNameServer.removePortNameMapping("_listener_");
      IsolateNameServer.registerPortWithName(
          _uiReceivePort.sendPort, "_listener_");

      _uiReceivePort.listen((message) {
        if (message is NotificationEvent) {
          _processEventInUI(message);
        }
      });

      // Also listen on standard plugin receive port for maximum reliability
      try {
        NotificationsListener.receivePort?.listen((message) {
          if (message is NotificationEvent) {
            _processEventInUI(message);
          }
        });
      } catch (_) {}

      notifyListeners();

      // Request runtime POST_NOTIFICATIONS on Android 13+ (API 33+)
      try {
        await _nativeHostChannel.invokeMethod('requestPostNotificationPermission');
      } catch (_) {}

      final hasPerm = await hasPermission();
      if (hasPerm && _isListening) {
        await _startUnderlyingService();
      }
    } catch (e) {
      developer.log('Initialization notice for NotificationsListener: $e',
          name: 'NotificationListenerManager');
    }
  }

  bool _hasPermission = false;
  bool get hasPermissionStatus => _hasPermission;

  /// Check if user has granted Notification Access permission in Android Settings
  /// Checks native AndroidX NotificationManagerCompat first, fallback to plugin.
  /// # O(1) time, O(1) space
  Future<bool> hasPermission() async {
    bool granted = false;
    // 1. Primary: Query native AndroidX NotificationManagerCompat
    try {
      final bool? nativeGranted = await _nativeHostChannel
          .invokeMethod<bool>('checkNotificationPermission');
      if (nativeGranted == true) {
        granted = true;
      }
    } catch (_) {}

    // 2. Secondary fallback: Query plugin property
    if (!granted) {
      try {
        final bool? pluginGranted = await NotificationsListener.hasPermission;
        granted = pluginGranted ?? false;
      } catch (_) {}
    }

    if (_hasPermission != granted) {
      _hasPermission = granted;
      notifyListeners();
    }

    return granted;
  }

  /// Open Android Notification Access Settings directly
  Future<void> requestPermission() async {
    try {
      final bool? opened = await _nativeHostChannel
          .invokeMethod<bool>('openNotificationListenerSettings');
      if (opened == true) return;
    } catch (_) {}

    try {
      await NotificationsListener.openPermissionSettings();
    } catch (e) {
      developer.log('Error opening permission settings: $e',
          name: 'NotificationListenerManager');
    }
  }

  /// Toggle notification tracking master switch
  Future<bool> toggleTracking(bool enable) async {
    try {
      _isListening = enable;
      await SecureStorageService.instance.setTrackingEnabled(enable);
      notifyListeners();

      if (enable) {
        final hasPerm = await hasPermission();
        if (hasPerm) {
          await _startUnderlyingService();
        }
      }
      // TRADE-OFF: Do NOT call NotificationsListener.stopService().
      // Plugin's stopService disables the Android Service Component in PackageManager,
      // which strips Android OS notification access permission, unbinds the service,
      // and causes subsequent startForegroundService ANR crashes.
      // Notifications are cleanly dropped in software by persistIncomingEvent when tracking is false.
      return true;
    } catch (e) {
      developer.log('Error toggling tracking: $e',
          name: 'NotificationListenerManager');
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

  /// Rebind the Android notification listener service component
  Future<void> rebindService() async {
    try {
      await _nativeHostChannel.invokeMethod('rebindNotificationListener');
    } catch (_) {}
  }

  /// Internal helper to start foreground/background service using dual native + plugin strategy
  Future<void> _startUnderlyingService() async {
    try {
      // 1. Direct native start and component rebind
      await _nativeHostChannel.invokeMethod('startNotificationListenerService');
    } catch (_) {}

    try {
      // 2. Plugin service start
      final isRunning = await NotificationsListener.isRunning;
      if (!(isRunning ?? false)) {
        await NotificationsListener.startService(
          title: "Smart Notification Tracker",
          description: "Monitoring incoming notifications in the background",
        );
      }
    } catch (_) {}
  }

  /// Process incoming notification event from UI isolate
  Future<void> _processEventInUI(NotificationEvent evt) async {
    // Notify listeners so timeline can refresh from SQLite
    notifyListeners();
    _notificationStreamController.add(const NotificationModel(
      packageName: '',
      appName: '',
      title: '',
      body: '',
      timestamp: 0,
    ));
  }

  /// Process incoming notification event safely from background isolate or main thread
  /// # O(1) time, O(1) space
  static Future<void> persistIncomingEvent(NotificationEvent evt) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // Check master tracking switch
      final isEnabled = await SecureStorageService.instance.isTrackingEnabled();
      if (!isEnabled) {
        developer.log(
            'Tracking disabled, dropping notification from ${evt.packageName}',
            name: 'NotificationListenerManager');
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
        developer.log('App filtered out by user: $packageName',
            name: 'NotificationListenerManager');
        return;
      }

      final String appName = _resolveHumanReadableAppName(packageName);
      final int timestamp = evt.createAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;

      final notification = NotificationModel(
        packageName: packageName,
        appName: appName,
        title: title.isEmpty ? appName : title,
        body: body,
        timestamp: timestamp,
      );

      final insertedId =
          await DatabaseHelper.instance.insertNotification(notification);
      developer.log(
          'Successfully recorded notification #$insertedId from $appName',
          name: 'NotificationListenerManager');
    } catch (e, st) {
      developer.log('Error in notification event handler: $e',
          error: e, stackTrace: st, name: 'NotificationListenerManager');
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
    _uiReceivePort.close();
    _notificationStreamController.close();
    super.dispose();
  }
}
