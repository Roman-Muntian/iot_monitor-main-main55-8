import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class ExportService {
  static Future<void> exportLogsToCSV(List<Map<String, dynamic>> logs) async {
    if (kIsWeb) {
      debugPrint("Експорт на Web: потрібен інший підхід.");
      return;
    }

    if (logs.isEmpty) return;

    final now = DateTime.now();

    // ── Заголовки ──────────────────────────────────────────────────
    List<List<dynamic>> csvData = [
      ['Дата', 'Час', 'Показник', 'Значення'],
    ];

    // ── Рядки даних ────────────────────────────────────────────────
    for (var log in logs) {
      final raw = log['timestamp']?.toString() ?? '';
      String date = '';
      String time = '';

      try {
        final dt = DateTime.parse(raw);
        // Дата: 23.05.2026
        date =
            '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
        // Час: 17:39
        time =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        date = raw;
        time = '';
      }

      final type = log['type'] == 'temp' ? 'Температура, °C' : 'Вологість, %';
      final value = log['value'];

      csvData.add([date, time, type, value]);
    }

    // ── CSV рядок ──────────────────────────────────────────────────
    // UTF-8 BOM — щоб Excel автоматично розпізнав кирилицю
    const bom = '\uFEFF';
    final csvContent = bom + const ListToCsvConverter(fieldDelimiter: ';').convert(csvData);

    try {
      final directory = await getTemporaryDirectory();

      // Назва: KlimaBox_23-05-2026.csv
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      final path = '${directory.path}/KlimaBox_$dateStr.csv';

      final file = File(path);
      await file.writeAsString(csvContent);

      await Share.shareXFiles(
        [XFile(path)],
        text: 'KlimaBox — телеметрія за $dateStr',
      );
    } catch (e) {
      debugPrint("Помилка під час експорту: $e");
    }
  }
}