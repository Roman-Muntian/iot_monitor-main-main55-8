import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;
  final List<Map<String, dynamic>> _webMemoryDb = [];
  bool _webLogsLoaded = false;

  // ← ОПТИМІЗАЦІЯ: лічильник замість DELETE при кожному записі
  int _insertCount = 0;

  Future<Database?> get db async {
    if (_db != null) return _db;
    _db = await _initDb();
    return _db;
  }

  Future<Database?> _initDb() async {
    if (kIsWeb) {
      await _loadWebLogs();
      return null;
    }

    String path = join(await getDatabasesPath(), 'iot_telemetry.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            type TEXT,
            value REAL
          )
        ''');
      },
    );
  }

  Future<void> _loadWebLogs() async {
    if (!kIsWeb || _webLogsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedData = prefs.getString('web_logs');
      if (savedData != null) {
        final List<dynamic> decoded = jsonDecode(savedData);
        _webMemoryDb.clear();
        _webMemoryDb.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
      }
      _webLogsLoaded = true;
    } catch (e) {
      debugPrint("Помилка завантаження Web-логів: $e");
    }
  }

  Future<void> _saveWebLogs() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_webMemoryDb.take(500).toList());
    await prefs.setString('web_logs', encodedData);
  }

  Future<void> insertLog(String type, double value) async {
    final now = DateTime.now();
    final cleanTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final cleanTimestamp = cleanTime.toIso8601String().split('.').first;

    if (kIsWeb) {
      await _loadWebLogs();
      _webMemoryDb.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch,
        'timestamp': cleanTimestamp,
        'type': type,
        'value': value,
      });
      if (_webMemoryDb.length > 1000) _webMemoryDb.removeLast();
      await _saveWebLogs();
      return;
    }

    final database = await db;
    await database!.insert('logs', {
      'timestamp': cleanTimestamp,
      'type': type,
      'value': value,
    });

    // ← ОПТИМІЗАЦІЯ: важкий DELETE лише раз на 100 записів
    // замість виконання при КОЖНОМУ insertLog
    _insertCount++;
    if (_insertCount % 100 == 0) {
      await database.execute('''
        DELETE FROM logs WHERE id NOT IN (
          SELECT id FROM logs ORDER BY id DESC LIMIT 1000
        )
      ''');
      debugPrint("DbService: очищення старих записів (вставлено $_insertCount)");
    }
  }

  Future<void> deleteLog(int id) async {
    if (kIsWeb) {
      await _loadWebLogs();
      _webMemoryDb.removeWhere((log) => log['id'] == id);
      await _saveWebLogs();
      return;
    }

    final database = await db;
    await database!.delete(
      'logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getLogs({
    String? type,
    String? date,
    int limit = 200, // ← ОПТИМІЗАЦІЯ з пункту 5: ліміт для аналітики
  }) async {
    if (kIsWeb) {
      await _loadWebLogs();
      final filtered = _webMemoryDb.where((log) {
        bool matchesType = (type == null || type == 'all') || (log['type'] == type);
        bool matchesDate = (date == null || date.isEmpty) ||
            (log['timestamp'].toString().startsWith(date));
        return matchesType && matchesDate;
      }).toList();
      // Застосовуємо ліміт і для веб
      return filtered.take(limit).toList();
    }

    final database = await db;
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (type != null && type != 'all') {
      where += ' AND type = ?';
      whereArgs.add(type);
    }

    if (date != null && date.isNotEmpty) {
      where += ' AND timestamp LIKE ?';
      whereArgs.add('$date%');
    }

    final result = await database!.query(
      'logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit, // ← передаємо ліміт у sqflite
    );
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> clearLogs() async {
    if (kIsWeb) {
      await _loadWebLogs();
      _webMemoryDb.clear();
      await _saveWebLogs();
      return;
    }

    final database = await db;
    await database!.delete('logs');
    _insertCount = 0; // ← скидаємо лічильник після повного очищення
  }
}