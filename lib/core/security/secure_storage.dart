// ─────────────────────────────────────────────────────
// Module   : lib/core/security/secure_storage.dart
// ─────────────────────────────────────────────────────

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hardware-backed secure storage manager handling encryption keys and passcode persistence.
class SecureStorageService {
  static const String _keyPasscode = 'sec_key_passcode_pin';
  static const String _keyBiometricsEnabled = 'sec_key_biometrics_enabled';
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

  /// Initialize default passcode ("123456") on first launch if not set
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

  /// Reset passcode back to default "123456"
  Future<void> resetToDefault() async {
    await _storage.write(key: _keyPasscode, value: _defaultPasscode);
    await _storage.write(key: _keyBiometricsEnabled, value: 'true');
  }
}
