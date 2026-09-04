// ─────────────────────────────────────────────────────
// Module   : lib/features/settings/presentation/settings_screen.dart
// ─────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/security/secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_service.dart';
import '../../auth/presentation/passcode_modal.dart';
import '../../notifications/data/notification_listener_service.dart';
import 'app_filter_screen.dart';
import 'export_dialog.dart';

/// Centralized Settings Screen gathering all controls:
/// Tracking toggle, Theme mode selector, App Filter navigation,
/// JSON Export, Security/Passcode, and Database cleanup.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _isTracking = true;
  bool _hasPermission = false;
  bool _biometricsEnabled = true;
  bool _canCheckBiometrics = false;
  int _totalRecordCount = 0;
  ThemeMode _currentTheme = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Instant pre-population from current memory state to prevent switch flicker
    _isTracking = NotificationListenerManager.instance.isListening;
    _currentTheme = ThemeService.instance.themeMode;
    _loadAllSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-verify system permissions and refreshed states when returning from Android Settings
      _loadAllSettings();
    }
  }

  Future<void> _loadAllSettings() async {
    try {
      final tracking = await SecureStorageService.instance.isTrackingEnabled();
      final perm = await NotificationListenerManager.instance.hasPermission();
      final bioPref = await SecureStorageService.instance.isBiometricsEnabled();
      final bioAvail = await BiometricService.instance.isBiometricsAvailable();
      final count = await DatabaseHelper.instance.getNotificationsCount();
      final theme = ThemeService.instance.themeMode;

      if (perm && tracking) {
        // Automatically start and rebind service when permission is active
        await NotificationListenerManager.instance.startListening();
      }

      if (mounted) {
        setState(() {
          _isTracking = tracking;
          _hasPermission = perm;
          _biometricsEnabled = bioPref;
          _canCheckBiometrics = bioAvail;
          _totalRecordCount = count;
          _currentTheme = theme;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleTracking(bool value) async {
    setState(() => _isTracking = value);
    await NotificationListenerManager.instance.toggleTracking(value);
  }

  Future<void> _changeTheme(ThemeMode mode) async {
    await ThemeService.instance.setThemeMode(mode);
    setState(() => _currentTheme = mode);
  }

  Future<void> _confirmClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Timeline Records?'),
        content: const Text(
          'This will permanently wipe all recorded notifications from local storage. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Wipe Database'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.clearAllNotifications();
      _loadAllSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notification records have been cleared.'),
            backgroundColor: AppTheme.accentEmerald,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? AppTheme.primaryLight : AppTheme.primaryDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ─── 1. NOTIFICATION TRACKING SECTION ─────────────
          _buildSectionHeader('NOTIFICATION TRACKING', isDark),
          _buildCard(
            isDark,
            children: [
              // Master Tracking Switch
              SwitchListTile(
                title: const Text('Capture Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                subtitle: Text(
                  _isTracking
                      ? 'Active — Saving incoming notifications to timeline'
                      : 'Paused — Temporarily ignoring incoming notifications',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
                secondary: Icon(
                  _isTracking ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: _isTracking ? AppTheme.accentEmerald : AppTheme.darkTextMuted,
                ),
                value: _isTracking,
                onChanged: _toggleTracking,
              ),
              Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              // System Permission Status
              ListTile(
                leading: Icon(
                  _hasPermission ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                  color: _hasPermission ? AppTheme.accentEmerald : AppTheme.accentAmber,
                ),
                title: const Text('Android Notification Access', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  _hasPermission ? 'Granted in System Settings' : 'Permission Required to read notifications',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                ),
                trailing: _hasPermission
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.accentEmerald, size: 20)
                    : TextButton(
                        onPressed: () async {
                          await NotificationListenerManager.instance.requestPermission();
                          _loadAllSettings();
                        },
                        child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ─── 2. APPEARANCE SECTION ────────────────────────
          _buildSectionHeader('APPEARANCE & THEME', isDark),
          _buildCard(
            isDark,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.palette_outlined, size: 20),
                        SizedBox(width: 10),
                        Text('Theme Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded, size: 16),
                          label: Text('Dark'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded, size: 16),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_suggest_rounded, size: 16),
                          label: Text('System'),
                        ),
                      ],
                      selected: {_currentTheme},
                      onSelectionChanged: (Set<ThemeMode> selection) {
                        _changeTheme(selection.first);
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ─── 3. APP RULES & FILTERS ───────────────────────
          _buildSectionHeader('APP RULES & BLACKLIST', isDark),
          _buildCard(
            isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.tune_rounded, color: AppTheme.primaryLight),
                title: const Text('Installed App Filters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                subtitle: const Text(
                  'Choose which apps are tracked or ignored on your device',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppFilterScreen()),
                  );
                  _loadAllSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ─── 4. DATA & EXPORT ─────────────────────────────
          _buildSectionHeader('DATA MANAGEMENT & EXPORT', isDark),
          _buildCard(
            isDark,
            children: [
              ListTile(
                leading: Icon(Icons.ios_share_rounded, color: primaryAccent),
                title: const Text('Export Timeline to JSON', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                subtitle: const Text(
                  'Select date range and export notifications to Share Sheet',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const ExportDialog(),
                  );
                },
              ),
              Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRose),
                title: const Text('Clear All Timeline History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.accentRose)),
                subtitle: Text(
                  '$_totalRecordCount records currently saved in SQLite',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                ),
                onTap: _confirmClearAll,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ─── 5. SECURITY & PASSCODE ───────────────────────
          _buildSectionHeader('SECURITY & AUTHENTICATION', isDark),
          _buildCard(
            isDark,
            children: [
              if (_canCheckBiometrics) ...[
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded, color: AppTheme.primaryLight),
                  title: const Text('Biometric Unlock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Prompt for fingerprint or face on launch', style: TextStyle(fontSize: 12)),
                  value: _biometricsEnabled,
                  onChanged: (val) async {
                    await SecureStorageService.instance.setBiometricsEnabled(val);
                    setState(() => _biometricsEnabled = val);
                  },
                ),
                Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ],
              ListTile(
                leading: const Icon(Icons.password_rounded, color: AppTheme.primaryLight),
                title: const Text('Change 6-Digit Passcode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                subtitle: const Text('Update your fallback lock PIN', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const PasscodeModal(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── 6. ABOUT ─────────────────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  'Smart Notification Timeline & Tracker',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  'v1.0.0 • Production Release',
                  style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
