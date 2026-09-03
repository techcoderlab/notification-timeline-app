// ─────────────────────────────────────────────────────
// Module   : lib/core/utils/json_exporter.dart
// ─────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

/// Result object for JSON export operation
class ExportResult {
  final bool isSuccess;
  final int recordCount;
  final String? filePath;
  final String? errorMessage;

  const ExportResult({
    required this.isSuccess,
    required this.recordCount,
    this.filePath,
    this.errorMessage,
  });
}

/// Utility class for querying notification timeline records, serializing to structured JSON,
/// and sharing via the native Android Share Sheet.
class JsonExporter {
  JsonExporter._();

  /// Export notifications within [startTimestamp] and [endTimestamp] to a formatted JSON file
  /// and trigger the native platform share dialog.
  /// # O(n) time, O(n) space where n is the number of notifications in range
  static Future<ExportResult> exportAndShareRange({
    required int startTimestamp,
    required int endTimestamp,
  }) async {
    try {
      final notifications = await DatabaseHelper.instance.getNotificationsByDateRange(
        startTimestamp,
        endTimestamp,
      );

      if (notifications.isEmpty) {
        return const ExportResult(
          isSuccess: false,
          recordCount: 0,
          errorMessage: 'No notifications found in the selected date range.',
        );
      }

      final startDate = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
      final endDate = DateTime.fromMillisecondsSinceEpoch(endTimestamp);
      final dateFormat = DateFormat('yyyy-MM-dd_HHmm');
      final humanDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

      // Build structured JSON envelope
      final Map<String, dynamic> exportPayload = {
        'metadata': {
          'application': 'Smart Notification Timeline & Tracker',
          'schema_version': '1.0.0',
          'exported_at_iso': DateTime.now().toUtc().toIso8601String(),
          'date_range': {
            'start_timestamp': startTimestamp,
            'start_datetime': humanDateFormat.format(startDate),
            'end_timestamp': endTimestamp,
            'end_datetime': humanDateFormat.format(endDate),
          },
          'total_records': notifications.length,
        },
        'records': notifications.map((n) => n.toJson()).toList(),
      };

      // Pretty-print JSON for readability
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(exportPayload);

      // Write to temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'notifications_export_${dateFormat.format(startDate)}_to_${dateFormat.format(endDate)}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString, flush: true);

      // Share file using SharePlus
      final xFile = XFile(file.path, mimeType: 'application/json', name: fileName);
      final shareResult = await Share.shareXFiles(
        [xFile],
        subject: 'Notification Timeline Export (${notifications.length} items)',
        text: 'Exported ${notifications.length} notifications from $fileName',
      );

      return ExportResult(
        isSuccess: shareResult.status != ShareResultStatus.dismissed,
        recordCount: notifications.length,
        filePath: file.path,
      );
    } catch (e) {
      return ExportResult(
        isSuccess: false,
        recordCount: 0,
        errorMessage: 'Export failed: ${e.toString()}',
      );
    }
  }
}
