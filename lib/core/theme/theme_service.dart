// ─────────────────────────────────────────────────────
// Module   : lib/core/theme/theme_service.dart
// ─────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../security/secure_storage.dart';

/// Service managing dynamic theme mode selection with persistence.
class ThemeService with ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Load persisted theme preference on app bootstrap
  Future<void> initialize() async {
    _themeMode = await SecureStorageService.instance.getThemeMode();
    notifyListeners();
  }

  /// Change theme mode and persist selection
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await SecureStorageService.instance.setThemeMode(mode);
  }
}
