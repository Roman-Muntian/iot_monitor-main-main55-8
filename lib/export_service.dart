import 'dart:convert'; // Додано для utf8.encode
import 'dart:typed_data'; // Додано для Uint8List
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class ExportService {
  static Future<void> exportLogsToCSV(List<Map<String, dynamic>> logs) async {
    if (logs.isEmpty) return;

    final now = DateTime.now();
    
    // Назва файлу: KlimaBox_23-05-2026.csv
    final dateStr = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    final fileName = 'KlimaBox_$dateStr.csv';

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
        date = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
        // Час: 17:39
        time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
      if (kIsWeb) {
        // ВИПРАВЛЕНО ДЛЯ WEB:
        // На вебі ми не можемо писати у файлову систему (File). 
        // Тому створюємо файл прямо в пам'яті з байтів. 
        // share_plus на Web автоматично ініціює завантаження (download) цього файлу браузером.
        final bytes = utf8.encode(csvContent);
        final xFile = XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: 'text/csv',
          name: fileName,
        );

        await Share.shareXFiles(
          [xFile],
          text: 'KlimaBox — телеметрія за $dateStr',
        );
      } else {
        // ДЛЯ МОБІЛЬНИХ ПЛАТФОРМ (iOS / Android):
        // Залишаємо збереження у тимчасову папку для коректної роботи Share Sheet
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/$fileName';

        final file = File(path);
        await file.writeAsString(csvContent);

        await Share.shareXFiles(
          [XFile(path)],
          text: 'KlimaBox — телеметрія за $dateStr',
        );
      }
    } catch (e) {
      debugPrint("Помилка під час експорту: $e");
    }
  }
}