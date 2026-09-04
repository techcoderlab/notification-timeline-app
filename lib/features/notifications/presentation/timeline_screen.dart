// ─────────────────────────────────────────────────────
// Module   : lib/features/notifications/presentation/timeline_screen.dart
// ─────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/presentation/settings_screen.dart';
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
  bool _isTracking = true;
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
    final isListening = NotificationListenerManager.instance.isListening;
    if (hasPerm && isListening) {
      await NotificationListenerManager.instance.startListening();
    }
    if (mounted) {
      setState(() {
        _hasPermission = hasPerm;
        _isTracking = isListening;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Timeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _isTracking ? AppTheme.accentEmerald : AppTheme.accentAmber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isTracking ? 'Tracker Active' : 'Tracker Paused',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Centralized Settings Screen Trigger
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _checkPermissionsAndStatus();
              _loadNotifications();
            },
          ),
          const SizedBox(width: 6),
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
                color: AppTheme.accentAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 22, color: AppTheme.accentAmber),
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
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.darkTextMuted),
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
                _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.notifications_off_outlined,
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
