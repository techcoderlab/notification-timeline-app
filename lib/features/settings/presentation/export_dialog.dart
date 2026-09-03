// ─────────────────────────────────────────────────────
// Module   : lib/features/settings/presentation/export_dialog.dart
// ─────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/json_exporter.dart';

enum ExportRangePreset {
  today,
  last7Days,
  last30Days,
  custom,
}

/// Dialog allowing users to select a date range (with quick presets or calendar picker),
/// inspect matching record count, and export formatted JSON to the native Share Sheet.
class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportRangePreset _preset = ExportRangePreset.last7Days;
  late DateTime _startDate;
  late DateTime _endDate;
  int _matchingRecordCount = 0;
  bool _isCounting = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _applyPreset(ExportRangePreset.last7Days, triggerCountUpdate: false);
    _updateRecordCount();
  }

  void _applyPreset(ExportRangePreset preset, {bool triggerCountUpdate = true}) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (preset) {
      case ExportRangePreset.today:
        _startDate = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
        _endDate = endOfToday;
        break;
      case ExportRangePreset.last7Days:
        _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        _endDate = endOfToday;
        break;
      case ExportRangePreset.last30Days:
        _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
        _endDate = endOfToday;
        break;
      case ExportRangePreset.custom:
        break;
    }

    _preset = preset;
    if (triggerCountUpdate) {
      _updateRecordCount();
    }
  }

  /// Query SQLite for notification count in current range
  /// # O(1) time with timestamp index, O(1) space
  Future<void> _updateRecordCount() async {
    setState(() => _isCounting = true);
    final count = await DatabaseHelper.instance.getNotificationsCount(
      startTimestamp: _startDate.millisecondsSinceEpoch,
      endTimestamp: _endDate.millisecondsSinceEpoch,
    );

    if (mounted) {
      setState(() {
        _matchingRecordCount = count;
        _isCounting = false;
      });
    }
  }

  /// Open Flutter DateRangePicker for custom range selection
  Future<void> _pickCustomDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _preset = ExportRangePreset.custom;
        _startDate = DateTime(pickedRange.start.year, pickedRange.start.month, pickedRange.start.day, 0, 0, 0);
        _endDate = DateTime(pickedRange.end.year, pickedRange.end.month, pickedRange.end.day, 23, 59, 59, 999);
      });
      _updateRecordCount();
    }
  }

  /// Execute export and open share sheet
  Future<void> _executeExport() async {
    if (_matchingRecordCount == 0) return;

    setState(() => _isExporting = true);

    final result = await JsonExporter.exportAndShareRange(
      startTimestamp: _startDate.millisecondsSinceEpoch,
      endTimestamp: _endDate.millisecondsSinceEpoch,
    );

    if (mounted) {
      setState(() => _isExporting = false);
      if (result.isSuccess) {
        Navigator.pop(context);
      } else if (result.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage!),
            backgroundColor: AppTheme.accentRose,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? AppTheme.primaryLight : AppTheme.primaryDark;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.ios_share_rounded, size: 22, color: primaryAccent),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Export Timeline', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(
                        'Generate structured JSON file',
                        style: TextStyle(fontSize: 12, color: AppTheme.darkTextMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Range Preset Segmented Chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip('Today', ExportRangePreset.today, isDark),
                _buildPresetChip('Last 7 Days', ExportRangePreset.last7Days, isDark),
                _buildPresetChip('Last 30 Days', ExportRangePreset.last30Days, isDark),
                _buildPresetChip('Custom', ExportRangePreset.custom, isDark, onTap: _pickCustomDateRange),
              ],
            ),
            const SizedBox(height: 16),

            // Date Range Display Card
            InkWell(
              onTap: _pickCustomDateRange,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.darkTextMuted),
                        const SizedBox(width: 8),
                        Text(
                          '${dateFormat.format(_startDate)}  —  ${dateFormat.format(_endDate)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.darkTextMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Record Count Summary Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.primary : AppTheme.primaryDark).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 18, color: primaryAccent),
                  const SizedBox(width: 8),
                  Text(
                    _isCounting ? 'Counting records...' : '$_matchingRecordCount records found',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isExporting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_matchingRecordCount > 0 && !_isExporting && !_isCounting)
                        ? _executeExport
                        : null,
                    child: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Share JSON'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    ExportRangePreset preset,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    final isSelected = _preset == preset;
    final primaryAccent = isDark ? AppTheme.primaryLight : AppTheme.primaryDark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        if (onTap != null) {
          onTap();
        } else {
          setState(() => _applyPreset(preset));
        }
      },
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
      ),
      selectedColor: primaryAccent,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      side: BorderSide(
        color: isSelected ? primaryAccent : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
