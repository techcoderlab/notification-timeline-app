// ─────────────────────────────────────────────────────
// Module   : lib/features/settings/presentation/app_filter_screen.dart
// ─────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/models/notification_model.dart';

/// Screen allowing users to inspect tracked application packages and toggle
/// notification capture rules individually or in bulk.
class AppFilterScreen extends StatefulWidget {
  const AppFilterScreen({super.key});

  @override
  State<AppFilterScreen> createState() => _AppFilterScreenState();
}

class _AppFilterScreenState extends State<AppFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AppFilterModel> _filters = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load app filter rules from SQLite
  /// # O(n) time, O(n) space
  Future<void> _loadFilters() async {
    setState(() => _isLoading = true);
    try {
      final items = await DatabaseHelper.instance.getAllAppFilters();
      if (mounted) {
        setState(() {
          _filters = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Toggle single application tracking rule
  Future<void> _toggleFilter(AppFilterModel filter, bool newValue) async {
    // Optimistic UI update
    setState(() {
      final index = _filters.indexWhere((f) => f.packageName == filter.packageName);
      if (index != -1) {
        _filters[index] = filter.copyWith(isEnabled: newValue);
      }
    });

    await DatabaseHelper.instance.upsertAppFilter(
      filter.packageName,
      filter.appName,
      newValue,
    );
  }

  /// Bulk toggle all filters enabled / disabled
  Future<void> _toggleAll(bool enableAll) async {
    setState(() {
      _filters = _filters.map((f) => f.copyWith(isEnabled: enableAll)).toList();
    });

    await DatabaseHelper.instance.toggleAllAppFilters(enableAll);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = _filters.where((f) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return f.appName.toLowerCase().contains(q) || f.packageName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          TextButton.icon(
            onPressed: () => _toggleAll(true),
            icon: const Icon(LucideIcons.checkCheck, size: 16),
            label: const Text('All On', style: TextStyle(fontSize: 12)),
          ),
          TextButton.icon(
            onPressed: () => _toggleAll(false),
            icon: const Icon(LucideIcons.ban, size: 16, color: AppTheme.accentRose),
            label: const Text('All Off', style: TextStyle(fontSize: 12, color: AppTheme.accentRose)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search applications...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // Apps List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                : filteredList.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = filteredList[index];

                          return Material(
                            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                            borderRadius: BorderRadius.circular(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  // App Initial Icon Avatar
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: (isDark ? AppTheme.primaryLight : AppTheme.primaryDark).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.appName.isNotEmpty ? item.appName[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppTheme.primaryLight : AppTheme.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // App Name & Package Identifier
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.appName,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.packageName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Enable/Disable Switch
                                  Switch(
                                    value: item.isEnabled,
                                    onChanged: (val) => _toggleFilter(item, val),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.slidersHorizontal,
              size: 40,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isNotEmpty ? 'No Apps Matching Search' : 'No Apps Tracked Yet',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Check your spelling or clear search filters.'
                  : 'As new notifications arrive, their respective apps will be listed here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
