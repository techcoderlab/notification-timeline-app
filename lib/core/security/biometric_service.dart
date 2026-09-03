// ─────────────────────────────────────────────────────
// Module   : lib/core/security/biometric_service.dart
// ─────────────────────────────────────────────────────

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Result status of a biometric authentication attempt
enum BiometricAuthResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  lockedOut,
  userCanceled,
}

/// Service managing device biometric authentication (Fingerprint, Face Unlock)
class BiometricService {
  // Singleton instance
  static final BiometricService instance = BiometricService._internal();
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if hardware supports biometrics and is ready
  /// # O(1) time, O(1) space
  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Check available biometric types (fingerprint, face, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return const [];
    }
  }

  /// Trigger native biometric prompt
  /// # O(1) time, O(1) space
  Future<BiometricAuthResult> authenticate({
    String localizedReason = 'Authenticate to access your Notification Timeline',
  }) async {
    try {
      final bool isAvailable = await isBiometricsAvailable();
      if (!isAvailable) {
        return BiometricAuthResult.notAvailable;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return didAuthenticate ? BiometricAuthResult.success : BiometricAuthResult.failed;
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'NotAvailable':
          return BiometricAuthResult.notAvailable;
        case 'NotEnrolled':
          return BiometricAuthResult.notEnrolled;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return BiometricAuthResult.lockedOut;
        case 'UserCancel':
        case 'SystemCancel':
          return BiometricAuthResult.userCanceled;
        default:
          return BiometricAuthResult.failed;
      }
    } catch (_) {
      return BiometricAuthResult.failed;
    }
  }
}
