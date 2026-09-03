// ─────────────────────────────────────────────────────
// Module   : lib/features/notifications/models/notification_model.dart
// ─────────────────────────────────────────────────────

import 'package:intl/intl.dart';

/// Immutable domain model representing a captured notification record.
class NotificationModel {
  final int? id;
  final String packageName;
  final String appName;
  final String title;
  final String body;
  final int timestamp; // Milliseconds since epoch

  const NotificationModel({
    this.id,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  /// Convert SQLite/JSON Map to NotificationModel instance
  /// # O(1) time, O(1) space
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      packageName: map['package_name'] as String? ?? 'unknown.package',
      appName: map['app_name'] as String? ?? 'Unknown App',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      timestamp: map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Convert NotificationModel instance to SQLite/JSON Map
  /// # O(1) time, O(1) space
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'package_name': packageName,
      'app_name': appName,
      'title': title,
      'body': body,
      'timestamp': timestamp,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// JSON serialization representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'package_name': packageName,
      'app_name': appName,
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'datetime_iso': dateTime.toIso8601String(),
      'formatted_time': formattedTime,
      'formatted_date': formattedDate,
    };
  }

  /// DateTime representation derived from timestamp
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// Formatted time string (e.g., "10:45 AM" or "22:45")
  String get formattedTime => DateFormat.jm().format(dateTime);

  /// Formatted date string (e.g., "03 Sep 2026")
  String get formattedDate => DateFormat('dd MMM yyyy').format(dateTime);

  /// Group key representing calendar day for timeline grouping ("Today", "Yesterday", or "dd MMM yyyy")
  /// # O(1) time, O(1) space
  String get dateGroupKey {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMMM yyyy').format(dateTime);
    }
  }

  NotificationModel copyWith({
    int? id,
    String? packageName,
    String? appName,
    String? title,
    String? body,
    int? timestamp,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          packageName == other.packageName &&
          appName == other.appName &&
          title == other.title &&
          body == other.body &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      packageName.hashCode ^
      appName.hashCode ^
      title.hashCode ^
      body.hashCode ^
      timestamp.hashCode;
}

/// Model representing an app filter entry in SQLite
class AppFilterModel {
  final String packageName;
  final String appName;
  final bool isEnabled;

  const AppFilterModel({
    required this.packageName,
    required this.appName,
    this.isEnabled = true,
  });

  factory AppFilterModel.fromMap(Map<String, dynamic> map) {
    return AppFilterModel(
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String? ?? map['package_name'] as String,
      isEnabled: (map['is_enabled'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'package_name': packageName,
      'app_name': appName,
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  AppFilterModel copyWith({
    String? packageName,
    String? appName,
    bool? isEnabled,
  }) {
    return AppFilterModel(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
