// ─────────────────────────────────────────────────────
// Module   : lib/core/security/secure_storage.dart
// ─────────────────────────────────────────────────────

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/database_helper.dart';

/// Hardware-backed secure storage manager handling encryption keys, passcode persistence,
/// theme mode preference, and notification tracking state with multi-tier caching (Memory + SQLite + Keystore).
class SecureStorageService {
  static const String _keyPasscode = 'sec_key_passcode_pin';
  static const String _keyBiometricsEnabled = 'sec_key_biometrics_enabled';
  static const String _keyThemeMode = 'sec_key_theme_mode';
  static const String _keyTrackingEnabled = 'sec_key_tracking_enabled';
  static const String _defaultPasscode = '123456';

  // Singleton instance
  static final SecureStorageService instance = SecureStorageService._internal();
  SecureStorageService._internal();

  // Tier 1 In-Memory Cache for sub-millisecond, synchronous-speed reads
  final Map<String, String> _memoryCache = {};

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Helper to safely read a key across Memory, SQLite, and SecureStorage
  /// # O(1) time, O(1) space
  Future<String?> _safeRead(String key) async {
    // 1. Check Tier 1 Memory Cache
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }

    // 2. Check Tier 2 SQLite Persistent Storage
    try {
      final dbVal = await DatabaseHelper.instance.getSetting(key);
      if (dbVal != null) {
        _memoryCache[key] = dbVal;
        return dbVal;
      }
    } catch (_) {}

    // 3. Check Tier 3 Hardware Keystore / Secure Storage
    try {
      final secVal = await _storage.read(key: key);
      if (secVal != null) {
        _memoryCache[key] = secVal;
        // Sync to SQLite for offline resilience
        await DatabaseHelper.instance.upsertSetting(key, secVal);
        return secVal;
      }
    } catch (e) {
      developer.log('SecureStorage read exception for $key: $e', name: 'SecureStorageService');
    }

    return null;
  }

  /// Helper to safely write across Memory, SQLite, and SecureStorage
  /// # O(1) time, O(1) space
  Future<void> _safeWrite(String key, String value) async {
    _memoryCache[key] = value;

    // Persist to Tier 2 SQLite first (always reliable on all Android versions)
    try {
      await DatabaseHelper.instance.upsertSetting(key, value);
    } catch (e) {
      developer.log('SQLite setting write exception: $e', name: 'SecureStorageService');
    }

    // Persist to Tier 3 Hardware Keystore
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      developer.log('SecureStorage write exception for $key: $e', name: 'SecureStorageService');
    }
  }

  /// Initialize default passcode ("123456") and settings on first launch if not set
  /// # O(1) time, O(1) space
  Future<void> initializeDefaults() async {
    final existingPin = await _safeRead(_keyPasscode);
    if (existingPin == null || existingPin.isEmpty) {
      await _safeWrite(_keyPasscode, _defaultPasscode);
    }

    final biometricsPref = await _safeRead(_keyBiometricsEnabled);
    if (biometricsPref == null) {
      await _safeWrite(_keyBiometricsEnabled, 'true');
    }

    final trackingPref = await _safeRead(_keyTrackingEnabled);
    if (trackingPref == null) {
      await _safeWrite(_keyTrackingEnabled, 'true');
    }

    final themePref = await _safeRead(_keyThemeMode);
    if (themePref == null) {
      await _safeWrite(_keyThemeMode, 'system');
    }
  }

  /// Retrieve stored 6-digit passcode
  Future<String> getPasscode() async {
    final pin = await _safeRead(_keyPasscode);
    return pin ?? _defaultPasscode;
  }

  /// Update 6-digit passcode
  Future<bool> setPasscode(String newPasscode) async {
    if (newPasscode.length != 6 || int.tryParse(newPasscode) == null) {
      return false;
    }
    await _safeWrite(_keyPasscode, newPasscode);
    return true;
  }

  /// Verify entered passcode against stored value
  /// # O(1) time, O(1) space
  Future<bool> verifyPasscode(String enteredPasscode) async {
    final storedPin = await getPasscode();
    return storedPin == enteredPasscode;
  }

  /// Check if biometric authentication is enabled in user settings
  Future<bool> isBiometricsEnabled() async {
    final pref = await _safeRead(_keyBiometricsEnabled);
    return pref != 'false';
  }

  /// Update biometrics toggle
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _safeWrite(_keyBiometricsEnabled, enabled ? 'true' : 'false');
  }

  /// Check if notification tracking is enabled (master switch)
  Future<bool> isTrackingEnabled() async {
    final pref = await _safeRead(_keyTrackingEnabled);
    return pref != 'false';
  }

  /// Update notification tracking master switch
  Future<void> setTrackingEnabled(bool enabled) async {
    await _safeWrite(_keyTrackingEnabled, enabled ? 'true' : 'false');
  }

  /// Retrieve user theme mode preference ('dark', 'light', 'system')
  Future<ThemeMode> getThemeMode() async {
    final modeStr = await _safeRead(_keyThemeMode);
    switch (modeStr) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Save user theme mode preference
  Future<void> setThemeMode(ThemeMode mode) async {
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
    }
    await _safeWrite(_keyThemeMode, modeStr);
  }

  /// Reset passcode back to default "123456"
  Future<void> resetToDefault() async {
    await _safeWrite(_keyPasscode, _defaultPasscode);
    await _safeWrite(_keyBiometricsEnabled, 'true');
    await _safeWrite(_keyTrackingEnabled, 'true');
    await _safeWrite(_keyThemeMode, 'system');
  }
}

