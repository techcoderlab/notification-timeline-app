// ─────────────────────────────────────────────────────
// Module   : lib/core/security/secure_storage.dart
// ─────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hardware-backed secure storage manager handling encryption keys, passcode persistence,
/// theme mode preference, and notification tracking state.
class SecureStorageService {
  static const String _keyPasscode = 'sec_key_passcode_pin';
  static const String _keyBiometricsEnabled = 'sec_key_biometrics_enabled';
  static const String _keyThemeMode = 'sec_key_theme_mode';
  static const String _keyTrackingEnabled = 'sec_key_tracking_enabled';
  static const String _defaultPasscode = '123456';

  // Singleton instance
  static final SecureStorageService instance = SecureStorageService._internal();
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Initialize default passcode ("123456") and settings on first launch if not set
  /// # O(1) time, O(1) space
  Future<void> initializeDefaults() async {
    final existingPin = await _storage.read(key: _keyPasscode);
    if (existingPin == null || existingPin.isEmpty) {
      await _storage.write(key: _keyPasscode, value: _defaultPasscode);
    }

    final biometricsPref = await _storage.read(key: _keyBiometricsEnabled);
    if (biometricsPref == null) {
      await _storage.write(key: _keyBiometricsEnabled, value: 'true');
    }

    final trackingPref = await _storage.read(key: _keyTrackingEnabled);
    if (trackingPref == null) {
      await _storage.write(key: _keyTrackingEnabled, value: 'true');
    }
  }

  /// Retrieve stored 6-digit passcode
  Future<String> getPasscode() async {
    final pin = await _storage.read(key: _keyPasscode);
    return pin ?? _defaultPasscode;
  }

  /// Update 6-digit passcode
  Future<bool> setPasscode(String newPasscode) async {
    if (newPasscode.length != 6 || int.tryParse(newPasscode) == null) {
      return false;
    }
    await _storage.write(key: _keyPasscode, value: newPasscode);
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
    final pref = await _storage.read(key: _keyBiometricsEnabled);
    return pref != 'false';
  }

  /// Update biometrics toggle
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(
      key: _keyBiometricsEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Check if notification tracking is enabled (master switch)
  Future<bool> isTrackingEnabled() async {
    final pref = await _storage.read(key: _keyTrackingEnabled);
    return pref != 'false';
  }

  /// Update notification tracking master switch
  Future<void> setTrackingEnabled(bool enabled) async {
    await _storage.write(
      key: _keyTrackingEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Retrieve user theme mode preference ('dark', 'light', 'system')
  Future<ThemeMode> getThemeMode() async {
    final modeStr = await _storage.read(key: _keyThemeMode);
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  /// Save user theme mode preference
  Future<void> setThemeMode(ThemeMode mode) async {
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
    }
    await _storage.write(key: _keyThemeMode, value: modeStr);
  }

  /// Reset passcode back to default "123456"
  Future<void> resetToDefault() async {
    await _storage.write(key: _keyPasscode, value: _defaultPasscode);
    await _storage.write(key: _keyBiometricsEnabled, value: 'true');
    await _storage.write(key: _keyTrackingEnabled, value: 'true');
    await _storage.write(key: _keyThemeMode, value: 'dark');
  }
}
