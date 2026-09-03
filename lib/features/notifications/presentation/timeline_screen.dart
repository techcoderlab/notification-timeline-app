// ─────────────────────────────────────────────────────
// Module   : lib/features/notifications/presentation/timeline_screen.dart
// ─────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/passcode_modal.dart';
import '../../settings/presentation/app_filter_screen.dart';
import '../../settings/presentation/export_dialog.dart';
import '../data/notification_listener_service.dart';
import '../models/notification_model.dart';
import 'widgets/date_header.dart';
import 'widgets/timeline_card.dart';

/// Main interactive Timeline feed displaying notifications grouped by date,
/// with live stream synchronization, full-text search, and quick management controls.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _isServiceRunning = false;
  String _searchQuery = '';
  StreamSubscription<NotificationModel>? _streamSubscription;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServicesAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _streamSubscription?.cancel();
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndStatus();
      _loadNotifications();
    }
  }

  Future<void> _initializeServicesAndLoad() async {
    await NotificationListenerManager.instance.initialize();
    await _checkPermissionsAndStatus();
    await _loadNotifications();

    // Subscribe to live incoming notifications stream
    _streamSubscription = NotificationListenerManager.instance.notificationStream.listen((_) {
      _loadNotifications(silent: true);
    });
  }

  Future<void> _checkPermissionsAndStatus() async {
    final hasPerm = await NotificationListenerManager.instance.hasPermission();
    final isRunning = NotificationListenerManager.instance.isListening;
    if (mounted) {
      setState(() {
        _hasPermission = hasPerm;
        _isServiceRunning = isRunning;
      });
    }
  }

  /// Load notifications from SQLite with optional debounced search query
  /// # O(n) time, O(n) space
  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final items = await DatabaseHelper.instance.getNotifications(
        limit: 200,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _searchQuery = query);
        _loadNotifications();
      }
    });
  }

  /// Delete a notification record with instant local update & undo capability
  Future<void> _deleteItem(NotificationModel item) async {
    if (item.id == null) return;

    final originalList = List<NotificationModel>.from(_notifications);
    setState(() {
      _notifications.removeWhere((n) => n.id == item.id);
    });

    final deletedCount = await DatabaseHelper.instance.deleteNotification(item.id!);

    if (mounted && deletedCount > 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed notification from ${item.appName}'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppTheme.accentCyan,
            onPressed: () async {
              await DatabaseHelper.instance.insertNotification(item);
              if (mounted) {
                setState(() => _notifications = originalList);
              }
            },
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Clear all notifications with confirmation
  Future<void> _promptClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Timeline?'),
        content: const Text('This will delete all recorded notifications permanently. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.clearAllNotifications();
      _loadNotifications();
    }
  }

  /// Group flat notification list into date dictionary
  /// # O(n) time, O(n) space
  Map<String, List<NotificationModel>> _groupNotificationsByDate(List<NotificationModel> list) {
    final Map<String, List<NotificationModel>> groups = {};
    for (final item in list) {
      final key = item.dateGroupKey;
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupedData = _groupNotificationsByDate(_notifications);
    final groupKeys = groupedData.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            Text(
              'Notification tracker & stream',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.darkTextMuted),
            ),
          ],
        ),
        actions: [
          // App Filters Screen Trigger
          IconButton(
            icon: const Icon(LucideIcons.filter, size: 20),
            tooltip: 'App Filter Rules',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppFilterScreen()),
              );
              _loadNotifications();
            },
          ),
          // Export JSON Trigger
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 20),
            tooltip: 'Export JSON',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ExportDialog(),
              );
            },
          ),
          // Settings / Security Popup Menu
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, size: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            onSelected: (value) async {
              if (value == 'change_pin') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const PasscodeModal(),
                );
              } else if (value == 'clear_all') {
                _promptClearAll();
              } else if (value == 'toggle_listener') {
                if (_isServiceRunning) {
                  await NotificationListenerManager.instance.stopListening();
                } else {
                  await NotificationListenerManager.instance.startListening();
                }
                _checkPermissionsAndStatus();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle_listener',
                child: Row(
                  children: [
                    Icon(
                      _isServiceRunning ? LucideIcons.pauseCircle : LucideIcons.playCircle,
                      size: 18,
                      color: _isServiceRunning ? AppTheme.accentAmber : AppTheme.accentEmerald,
                    ),
                    const SizedBox(width: 10),
                    Text(_isServiceRunning ? 'Pause Listener' : 'Start Listener'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'change_pin',
                child: Row(
                  children: [
                    Icon(LucideIcons.keyRound, size: 18, color: AppTheme.primaryLight),
                    const SizedBox(width: 10),
                    Text('Change Passcode'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 18, color: AppTheme.accentRose),
                    const SizedBox(width: 10),
                    Text('Clear All History', style: TextStyle(color: AppTheme.accentRose)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ─── Permission Banner (if not granted) ───────────
          if (!_hasPermission)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, size: 20, color: AppTheme.accentAmber),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Notification Access required to track incoming alerts.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accentAmber),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await NotificationListenerManager.instance.requestPermission();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),

          // ─── Live Search Bar ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search notifications by app, title, or body...',
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppTheme.darkTextMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // ─── Timeline Feed Content ─────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                : _notifications.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: () => _loadNotifications(),
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.only(bottom: 32),
                          itemCount: groupKeys.length,
                          itemBuilder: (context, groupIndex) {
                            final dateKey = groupKeys[groupIndex];
                            final itemsForDate = groupedData[dateKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DateHeaderWidget(
                                  dateTitle: dateKey,
                                  count: itemsForDate.length,
                                ),
                                ...itemsForDate.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final notification = entry.value;
                                  final isFirst = index == 0;
                                  final isLast = index == itemsForDate.length - 1;

                                  return TimelineCard(
                                    notification: notification,
                                    isFirst: isFirst,
                                    isLast: isLast,
                                    onDelete: () => _deleteItem(notification),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Clean empty state with minimalist illustration
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Icon(
                _searchQuery.isNotEmpty ? LucideIcons.searchX : LucideIcons.bellOff,
                size: 36,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No Matching Notifications' : 'Timeline Is Empty',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with different keywords.'
                  : 'Incoming alerts from enabled apps will appear here in chronological order.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
