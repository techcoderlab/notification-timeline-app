// ─────────────────────────────────────────────────────
// Module   : lib/features/auth/presentation/passcode_modal.dart
// ─────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/security/secure_storage.dart';
import '../../../core/theme/app_theme.dart';

enum PasscodeStep {
  verifyOld,
  enterNew,
  confirmNew,
}

/// Modal bottom sheet allowing users to change their 6-digit fallback PIN
/// and toggle biometric authentication preferences.
class PasscodeModal extends StatefulWidget {
  const PasscodeModal({super.key});

  @override
  State<PasscodeModal> createState() => _PasscodeModalState();
}

class _PasscodeModalState extends State<PasscodeModal> {
  PasscodeStep _step = PasscodeStep.verifyOld;
  String _pinBuffer = '';
  String _newPinCandidate = '';
  String _errorMessage = '';
  bool _biometricsEnabled = true;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityPreferences();
  }

  Future<void> _loadSecurityPreferences() async {
    final bioPref = await SecureStorageService.instance.isBiometricsEnabled();
    final bioAvail = await BiometricService.instance.isBiometricsAvailable();
    if (mounted) {
      setState(() {
        _biometricsEnabled = bioPref;
        _canCheckBiometrics = bioAvail;
      });
    }
  }

  void _onKeyPress(String digit) {
    if (_pinBuffer.length >= 6) return;

    HapticFeedback.lightImpact();
    setState(() {
      _pinBuffer += digit;
      _errorMessage = '';
    });

    if (_pinBuffer.length == 6) {
      _handleStepCompletion(_pinBuffer);
    }
  }

  void _onBackspace() {
    if (_pinBuffer.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _pinBuffer = _pinBuffer.substring(0, _pinBuffer.length - 1);
      _errorMessage = '';
    });
  }

  Future<void> _handleStepCompletion(String pin) async {
    if (_step == PasscodeStep.verifyOld) {
      final isValid = await SecureStorageService.instance.verifyPasscode(pin);
      if (isValid) {
        setState(() {
          _step = PasscodeStep.enterNew;
          _pinBuffer = '';
        });
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _pinBuffer = '';
          _errorMessage = 'Current passcode is incorrect.';
        });
      }
    } else if (_step == PasscodeStep.enterNew) {
      setState(() {
        _newPinCandidate = pin;
        _step = PasscodeStep.confirmNew;
        _pinBuffer = '';
      });
    } else if (_step == PasscodeStep.confirmNew) {
      if (pin == _newPinCandidate) {
        await SecureStorageService.instance.setPasscode(pin);
        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passcode updated successfully!'),
              backgroundColor: AppTheme.accentEmerald,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _step = PasscodeStep.enterNew;
          _newPinCandidate = '';
          _pinBuffer = '';
          _errorMessage = 'Passcodes did not match. Please try again.';
        });
      }
    }
  }

  String get _stepTitle {
    switch (_step) {
      case PasscodeStep.verifyOld:
        return 'Verify Current Passcode';
      case PasscodeStep.enterNew:
        return 'Enter New 6-Digit Passcode';
      case PasscodeStep.confirmNew:
        return 'Confirm New Passcode';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? AppTheme.primaryLight : AppTheme.primaryDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grab handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Security Settings Row (Biometrics Toggle)
          if (_canCheckBiometrics) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.fingerprint_rounded, size: 22, color: AppTheme.primaryLight),
                      SizedBox(width: 10),
                      Text('Biometric Unlock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Switch(
                    value: _biometricsEnabled,
                    onChanged: (val) async {
                      await SecureStorageService.instance.setBiometricsEnabled(val);
                      setState(() => _biometricsEnabled = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            _stepTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),

          // 6 Dots PIN indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final isFilled = index < _pinBuffer.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isFilled ? primaryAccent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isFilled ? primaryAccent : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),

          // Error message
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accentRose),
              ),
            ),
          ),

          // Numeric Keypad
          _buildCompactKeypad(isDark),
        ],
      ),
    );
  }

  Widget _buildCompactKeypad(bool isDark) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4', isDark),
              _buildKey('5', isDark),
              _buildKey('6', isDark),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7', isDark),
              _buildKey('8', isDark),
              _buildKey('9', isDark),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 58),
              _buildKey('0', isDark),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _onBackspace,
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: Center(
                      child: Icon(
                        Icons.backspace_outlined,
                        size: 22,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                ),
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
        borderRadius: BorderRadius.circular(29),
        side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(29),
        onTap: () => _onKeyPress(value),
        child: SizedBox(
          width: 58,
          height: 58,
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
