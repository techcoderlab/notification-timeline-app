// ─────────────────────────────────────────────────────
// Module   : lib/features/auth/presentation/lock_screen.dart
// ─────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/security/secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/presentation/timeline_screen.dart';

/// Primary authentication lock screen triggered upon application launch.
/// Attempts hardware biometrics first, providing a tactile 6-digit PIN keypad fallback.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _isVerifying = false;
  String _errorMessage = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Trigger biometrics automatically after layout render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptBiometricAuth();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// Attempt biometric authentication if enabled and supported
  Future<void> _attemptBiometricAuth() async {
    final biometricsEnabled = await SecureStorageService.instance.isBiometricsEnabled();
    if (!biometricsEnabled) return;

    final result = await BiometricService.instance.authenticate(
      localizedReason: 'Unlock your Smart Notification Timeline',
    );

    if (result == BiometricAuthResult.success && mounted) {
      _navigateToTimeline();
    }
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length >= 6 || _isVerifying) return;

    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit;
      _errorMessage = '';
    });

    if (_enteredPin.length == 6) {
      _verifyPin(_enteredPin);
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty || _isVerifying) return;

    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = '';
    });
  }

  /// Verify entered PIN against Secure Storage
  /// # O(1) time, O(1) space
  Future<void> _verifyPin(String pin) async {
    setState(() => _isVerifying = true);

    final isValid = await SecureStorageService.instance.verifyPasscode(pin);

    if (isValid && mounted) {
      HapticFeedback.mediumImpact();
      _navigateToTimeline();
    } else if (mounted) {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      setState(() {
        _isVerifying = false;
        _enteredPin = '';
        _errorMessage = 'Incorrect PIN. Try again.';
      });
    }
  }

  void _navigateToTimeline() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const TimelineScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? AppTheme.primaryLight : AppTheme.primaryDark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Shield Icon & App Title
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: primaryAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryAccent.withOpacity(0.25), width: 1.5),
                ),
                child: Icon(LucideIcons.shieldCheck, size: 30, color: primaryAccent),
              ),
              const SizedBox(height: 16),
              const Text(
                'Security Check',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your 6-digit passcode',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // 6-Digit PIN Indicator Dots with Shake Animation
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value * (1 - _shakeController.value), 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final isFilled = index < _enteredPin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: isFilled ? 14 : 12,
                          height: isFilled ? 14 : 12,
                          decoration: BoxDecoration(
                            color: isFilled ? primaryAccent : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isFilled ? primaryAccent : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),

              // Error Message Label
              SizedBox(
                height: 32,
                child: Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentRose,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Numeric Keypad Grid (0-9, Backspace, Biometric)
              _buildKeypad(isDark, primaryAccent),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark, Color primaryAccent) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1', isDark),
              _buildKey('2', isDark),
              _buildKey('3', isDark),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4', isDark),
              _buildKey('5', isDark),
              _buildKey('6', isDark),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7', isDark),
              _buildKey('8', isDark),
              _buildKey('9', isDark),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Biometric Trigger Button
              _buildActionKey(
                icon: LucideIcons.fingerprint,
                isDark: isDark,
                onTap: _attemptBiometricAuth,
              ),
              _buildKey('0', isDark),
              // Backspace Button
              _buildActionKey(
                icon: LucideIcons.delete,
                isDark: isDark,
                onTap: _onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value, bool isDark) {
    return Material(
      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(36),
        side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(36),
        onTap: () => _onKeyPress(value),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Icon(
              icon,
              size: 24,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
