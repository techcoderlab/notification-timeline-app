// ─────────────────────────────────────────────────────
// Module   : lib/features/notifications/presentation/widgets/app_tracker_icon.dart
// ─────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Branded tracker icon badge providing dynamic icons, subtle gradients,
/// and responsive fallback radar badges for notifications and app filter lists.
class AppTrackerIcon extends StatelessWidget {
  final String packageName;
  final String appName;
  final double size;

  const AppTrackerIcon({
    super.key,
    required this.packageName,
    required this.appName,
    this.size = 32,
  });

  /// Map package names to iconic symbols and curated color palettes
  /// # O(1) time, O(1) space
  _IconConfig _resolveConfig(bool isDark) {
    final pkg = packageName.toLowerCase();

    if (pkg.contains('whatsapp')) {
      return const _IconConfig(
        icon: Icons.chat_rounded,
        gradientStart: Color(0xFF10B981),
        gradientEnd: Color(0xFF059669),
        iconColor: Colors.white,
      );
    } else if (pkg.contains('gm') || pkg.contains('email') || pkg.contains('mail')) {
      return const _IconConfig(
        icon: Icons.mail_rounded,
        gradientStart: Color(0xFFF43F5E),
        gradientEnd: Color(0xFFBE123C),
        iconColor: Colors.white,
      );
    } else if (pkg.contains('youtube')) {
      return const _IconConfig(
        icon: Icons.play_arrow_rounded,
        gradientStart: Color(0xFFEF4444),
        gradientEnd: Color(0xFFB91C1C),
        iconColor: Colors.white,
      );
    } else if (pkg.contains('telegram')) {
      return const _IconConfig(
        icon: Icons.send_rounded,
        gradientStart: Color(0xFF0EA5E9),
        gradientEnd: Color(0xFF0284C7),
        iconColor: Colors.white,
      );
    } else if (pkg.contains('instagram')) {
      return const _IconConfig(
        icon: Icons.camera_alt_rounded,
        gradientStart: Color(0xFFD946EF),
        gradientEnd: Color(0xFF8B5CF6),
        iconColor: Colors.white,
      );
    } else if (pkg.contains('chrome') || pkg.contains('browser')) {
      return const _IconConfig(
        icon: Icons.language_rounded,
        gradientStart: Color(0xFF3B82F6),
        gradientEnd: Color(0xFF1D4ED8),
        iconColor: Colors.white,
      );
    } else if (pkg.contains('messaging') || pkg.contains('mms') || pkg.contains('sms')) {
      return const _IconConfig(
        icon: Icons.message_rounded,
        gradientStart: Color(0xFFF59E0B),
        gradientEnd: Color(0xFFD97706),
        iconColor: Colors.white,
      );
    } else if (pkg.contains('spotify') || pkg.contains('music')) {
      return const _IconConfig(
        icon: Icons.music_note_rounded,
        gradientStart: Color(0xFF22C55E),
        gradientEnd: Color(0xFF16A34A),
        iconColor: Colors.white,
      );
    } else if (pkg.contains('twitter') || pkg.contains('.x.')) {
      return const _IconConfig(
        icon: Icons.alternate_email_rounded,
        gradientStart: Color(0xFF64748B),
        gradientEnd: Color(0xFF334155),
        iconColor: Colors.white,
      );
    }

    // Default: Minimalist Tracker Radar Badge with app initial letter
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryDark;
    return _IconConfig(
      icon: Icons.radar_rounded,
      gradientStart: primary.withValues(alpha: 0.25),
      gradientEnd: primary.withValues(alpha: 0.12),
      iconColor: primary,
      useAppInitial: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _resolveConfig(isDark);
    final borderRadius = BorderRadius.circular(size * 0.28);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [config.gradientStart, config.gradientEnd],
        ),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: config.gradientStart.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Center(
        child: config.useAppInitial
            ? Text(
                appName.isNotEmpty ? appName[0].toUpperCase() : '•',
                style: TextStyle(
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w800,
                  color: config.iconColor,
                ),
              )
            : Icon(
                config.icon,
                size: size * 0.52,
                color: config.iconColor,
              ),
      ),
    );
  }
}

class _IconConfig {
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final Color iconColor;
  final bool useAppInitial;

  const _IconConfig({
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.iconColor,
    this.useAppInitial = false,
  });
}
