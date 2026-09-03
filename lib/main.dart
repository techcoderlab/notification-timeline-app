// ─────────────────────────────────────────────────────
// Module   : lib/main.dart (Application Bootstrap)
// ─────────────────────────────────────────────────────

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/database/database_helper.dart';
import 'core/security/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/lock_screen.dart';

/// Main entry point of the Smart Notification Timeline & Tracker application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay and lock portrait orientation
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.darkBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Pre-warm Secure Storage & Database connections
  try {
    await SecureStorageService.instance.initializeDefaults();
    await DatabaseHelper.instance.database;
  } catch (e, stackTrace) {
    developer.log('Bootstrap initialization warning: $e', error: e, stackTrace: stackTrace, name: 'Main');
  }

  runApp(const SmartNotificationTrackerApp());
}

/// Root Application Widget configuring themes, routing, and security gate
class SmartNotificationTrackerApp extends StatelessWidget {
  const SmartNotificationTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Notification Timeline & Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Default to OLED dark theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const LockScreen(),
    );
  }
}
