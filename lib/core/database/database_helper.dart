// ─────────────────────────────────────────────────────
// Module   : lib/core/database/database_helper.dart
// ─────────────────────────────────────────────────────

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/notifications/models/notification_model.dart';

/// Production-ready, thread-safe SQLite database manager for notifications and app filters.
/// Ensures indexed, non-blocking queries and atomic operations.
class DatabaseHelper {
  static const String _dbName = 'notification_tracker.db';
  static const int _dbVersion = 2;

  // Table Names
  static const String tableNotifications = 'notifications';
  static const String tableAppFilters = 'app_filters';
  static const String tableAppSettings = 'app_settings';

  // Notifications Column Names
  static const String colId = 'id';
  static const String colPackageName = 'package_name';
  static const String colAppName = 'app_name';
  static const String colTitle = 'title';
  static const String colBody = 'body';
  static const String colTimestamp = 'timestamp';

  // App Filters Column Names
  static const String colFilterPackageName = 'package_name';
  static const String colFilterAppName = 'app_name';
  static const String colFilterIsEnabled = 'is_enabled';

  // App Settings Column Names
  static const String colSettingKey = 'setting_key';
  static const String colSettingValue = 'setting_value';

  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;
  static Completer<Database>? _dbOpenCompleter;

  /// For unit and widget testing: allows injecting an in-memory or mock database instance
  static void setTestDatabase(Database? db) {
    _database = db;
  }

  /// Retrieve active database instance with mutex-style lazy initialization
  /// # O(1) time, O(1) space
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    if (_dbOpenCompleter != null) {
      return _dbOpenCompleter!.future;
    }

    final completer = Completer<Database>();
    _dbOpenCompleter = completer;

    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      final db = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: (db, version) async {
          await _createTablesIfNotExist(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _createTablesIfNotExist(db);
        },
        onConfigure: (db) async {
          // Enable SQLite Write-Ahead Logging (WAL) for concurrent read/write throughput
          await db.execute('PRAGMA journal_mode = WAL');
          await db.execute('PRAGMA synchronous = NORMAL');
        },
      );

      // Ensure all tables and indexes exist even on pre-existing database versions
      await _createTablesIfNotExist(db);

      _database = db;
      if (!completer.isCompleted) {
        completer.complete(db);
      }
      _dbOpenCompleter = null;
      return db;
    } catch (e) {
      _dbOpenCompleter = null;
      if (!completer.isCompleted) {
        // Suppress unhandled asynchronous Zone error in Flutter test harness
        completer.future.ignore();
        completer.completeError(e);
      }
      rethrow;
    }
  }

  /// Initial table and index creation with idempotent guards
  Future<void> _createTablesIfNotExist(Database db) async {
    // 1. App Filters Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableAppFilters (
        $colFilterPackageName TEXT PRIMARY KEY,
        $colFilterAppName TEXT NOT NULL,
        $colFilterIsEnabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 2. Notifications Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableNotifications (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colPackageName TEXT NOT NULL,
        $colAppName TEXT NOT NULL,
        $colTitle TEXT NOT NULL,
        $colBody TEXT NOT NULL,
        $colTimestamp INTEGER NOT NULL
      )
    ''');

    // 3. Composite Indexes for fast time-series queries and package lookups
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notifications_timestamp 
      ON $tableNotifications ($colTimestamp DESC)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notifications_pkg 
      ON $tableNotifications ($colPackageName)
    ''');

    // 4. App Settings Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableAppSettings (
        $colSettingKey TEXT PRIMARY KEY,
        $colSettingValue TEXT NOT NULL
      )
    ''');
  }

  // ─────────────────────────────────────────────────────
  // NOTIFICATION CRUD OPERATIONS
  // ─────────────────────────────────────────────────────

  /// Insert notification record only if app is enabled in filters
  /// Automatically registers new app package into app_filters if not already tracked.
  /// # O(1) time, O(1) space
  Future<int?> insertNotification(NotificationModel notification) async {
    final db = await database;

    // Check if app is allowed
    final isAllowed = await isAppAllowed(notification.packageName);
    if (!isAllowed) {
      return null;
    }

    // Upsert app into filters list so user can see and toggle it in App Filter Screen
    await upsertAppFilter(
      notification.packageName,
      notification.appName,
      true, // keep enabled
      onlyIfMissing: true,
    );

    return await db.insert(
      tableNotifications,
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch notifications with optional pagination and keyword search
  /// # O(n log n) time due to index sort, O(limit) space
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    int? startTimestamp,
    int? endTimestamp,
  }) async {
    final db = await database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final sanitizedQuery = '%${searchQuery.trim()}%';
      whereClauses.add('($colAppName LIKE ? OR $colTitle LIKE ? OR $colBody LIKE ?)');
      whereArgs.addAll([sanitizedQuery, sanitizedQuery, sanitizedQuery]);
    }

    if (startTimestamp != null) {
      whereClauses.add('$colTimestamp >= ?');
      whereArgs.add(startTimestamp);
    }

    if (endTimestamp != null) {
      whereClauses.add('$colTimestamp <= ?');
      whereArgs.add(endTimestamp);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final result = await db.query(
      tableNotifications,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: '$colTimestamp DESC',
      limit: limit,
      offset: offset,
    );

    return result.map((row) => NotificationModel.fromMap(row)).toList();
  }

  /// Fetch all notifications within a timestamp range for JSON export
  /// # O(n) time, O(n) space where n is records in range
  Future<List<NotificationModel>> getNotificationsByDateRange(
    int startTimestamp,
    int endTimestamp,
  ) async {
    final db = await database;
    final result = await db.query(
      tableNotifications,
      where: '$colTimestamp >= ? AND $colTimestamp <= ?',
      whereArgs: [startTimestamp, endTimestamp],
      orderBy: '$colTimestamp ASC',
    );

    return result.map((row) => NotificationModel.fromMap(row)).toList();
  }

  /// Get total notification count in given timestamp range
  Future<int> getNotificationsCount({int? startTimestamp, int? endTimestamp}) async {
    final db = await database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (startTimestamp != null) {
      whereClauses.add('$colTimestamp >= ?');
      whereArgs.add(startTimestamp);
    }
    if (endTimestamp != null) {
      whereClauses.add('$colTimestamp <= ?');
      whereArgs.add(endTimestamp);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableNotifications ${whereString != null ? "WHERE $whereString" : ""}',
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete a single notification by id
  Future<int> deleteNotification(int id) async {
    final db = await database;
    return await db.delete(
      tableNotifications,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// Clear all notifications from database
  Future<int> clearAllNotifications() async {
    final db = await database;
    return await db.delete(tableNotifications);
  }

  // ─────────────────────────────────────────────────────
  // APP FILTER CRUD OPERATIONS
  // ─────────────────────────────────────────────────────

  /// Check if notifications from this package should be logged
  /// # O(1) time, O(1) space
  Future<bool> isAppAllowed(String packageName) async {
    final db = await database;
    final result = await db.query(
      tableAppFilters,
      columns: [colFilterIsEnabled],
      where: '$colFilterPackageName = ?',
      whereArgs: [packageName],
      limit: 1,
    );

    if (result.isEmpty) {
      return true; // Default allowed if not yet registered
    }

    return (result.first[colFilterIsEnabled] as int? ?? 1) == 1;
  }

  /// Fetch all registered app filters
  Future<List<AppFilterModel>> getAllAppFilters() async {
    final db = await database;
    final result = await db.query(
      tableAppFilters,
      orderBy: '$colFilterAppName ASC',
    );

    return result.map((row) => AppFilterModel.fromMap(row)).toList();
  }

  /// Upsert app filter status
  Future<void> upsertAppFilter(
    String packageName,
    String appName,
    bool isEnabled, {
    bool onlyIfMissing = false,
  }) async {
    final db = await database;

    if (onlyIfMissing) {
      final existing = await db.query(
        tableAppFilters,
        where: '$colFilterPackageName = ?',
        whereArgs: [packageName],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return;
      }
    }

    await db.insert(
      tableAppFilters,
      {
        colFilterPackageName: packageName,
        colFilterAppName: appName,
        colFilterIsEnabled: isEnabled ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Toggle all app filters enabled/disabled in a single transaction
  Future<void> toggleAllAppFilters(bool enableAll) async {
    final db = await database;
    await db.update(
      tableAppFilters,
      {colFilterIsEnabled: enableAll ? 1 : 0},
    );
  }

  /// Batch-insert discovered apps into the app_filters table.
  /// Uses INSERT OR IGNORE so existing rows (with user-toggled states) are never overwritten.
  /// # O(n) time, O(n) space where n is the number of apps
  Future<void> batchUpsertAppFilters(List<Map<String, dynamic>> apps) async {
    if (apps.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final app in apps) {
      batch.rawInsert(
        'INSERT OR IGNORE INTO $tableAppFilters '
        '($colFilterPackageName, $colFilterAppName, $colFilterIsEnabled) '
        'VALUES (?, ?, ?)',
        [
          app['packageName'] as String,
          app['appName'] as String,
          (app['isEnabled'] as bool) ? 1 : 0,
        ],
      );
    }
    await batch.commit(noResult: true);
  }

  // ─────────────────────────────────────────────────────
  // APP SETTINGS OPERATIONS
  // ─────────────────────────────────────────────────────

  /// Retrieve persistent setting by key
  /// # O(1) time, O(1) space
  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final result = await db.query(
        tableAppSettings,
        columns: [colSettingValue],
        where: '$colSettingKey = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return result.first[colSettingValue] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Upsert persistent setting by key
  /// # O(1) time, O(1) space
  Future<void> upsertSetting(String key, String value) async {
    try {
      final db = await database;
      await db.insert(
        tableAppSettings,
        {
          colSettingKey: key,
          colSettingValue: value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Close database connection safely
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      _dbOpenCompleter = null;
    }
  }
}
