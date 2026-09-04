// ─────────────────────────────────────────────────────
// Module   : lib/features/notifications/presentation/widgets/timeline_card.dart
// ─────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/notification_model.dart';
import 'app_tracker_icon.dart';

/// Minimalist timeline notification card featuring soft rounded corners,
/// subtle vertical rail connector, bold app title, right-aligned muted timestamp,
/// 1-line constrained title, and 2-line constrained body.
class TimelineCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onDelete;

  const TimelineCard({
    super.key,
    required this.notification,
    this.isFirst = false,
    this.isLast = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final railColor = isDark ? AppTheme.darkConnector : AppTheme.lightConnector;
    final primaryAccent = isDark ? AppTheme.primaryLight : AppTheme.primaryDark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Vertical Timeline Rail ───────────────────────
          SizedBox(
            width: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top Connector Segment
                Positioned(
                  top: 0,
                  bottom: isFirst ? 0 : null,
                  height: isFirst ? null : 20,
                  width: 2,
                  child: Container(color: isFirst ? Colors.transparent : railColor),
                ),
                // Bottom Connector Segment
                Positioned(
                  top: 20,
                  bottom: 0,
                  width: 2,
                  child: Container(color: isLast ? Colors.transparent : railColor),
                ),
                // Timeline Dot Indicator
                Positioned(
                  top: 18,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: primaryAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryAccent.withValues(alpha: 0.35),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Notification Card Surface ────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 4, bottom: 8),
              child: Dismissible(
                key: ValueKey('notification_${notification.id}_${notification.timestamp}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRose.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                ),
                onDismissed: (_) => onDelete?.call(),
                child: Material(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: borderColor, width: 1),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showNotificationDetailModal(context),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Name & Timestamp Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    AppTrackerIcon(
                                      packageName: notification.packageName,
                                      appName: notification.appName,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        notification.appName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                notification.formattedTime,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                                ),
                              ),
                            ],
                          ),

                          // Notification Title (1 line max)
                          if (notification.title.isNotEmpty && notification.title != notification.appName) ...[
                            const SizedBox(height: 6),
                            Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                letterSpacing: -0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          // Notification Body (2 lines max)
                          if (notification.body.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              notification.body,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 1.35,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show clean modal bottom sheet with complete notification contents
  void _showNotificationDetailModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal grab handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header info with AppTrackerIcon
            Row(
              children: [
                AppTrackerIcon(
                  packageName: notification.packageName,
                  appName: notification.appName,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.appName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.packageName,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${notification.formattedDate}\n${notification.formattedTime}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, height: 1),
            const SizedBox(height: 16),

            // Full Title
            if (notification.title.isNotEmpty) ...[
              const Text(
                'Title',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
              ),
              const SizedBox(height: 4),
              Text(
                notification.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
            ],

            // Full Body
            if (notification.body.isNotEmpty) ...[
              const Text(
                'Message Content',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
              ),
              const SizedBox(height: 4),
              SelectableText(
                notification.body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Close Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
