// =====================================================================
//  LOG SCREEN — NEO-BRUTALIST EVENT LOG
//
//  Logic preserved: filter chips, date filter, dismiss-to-delete,
//  ascending toggle, CSV export — all unchanged.
//
//  ── ISSUE FIXES ──
//  • FutureBuilder removed: Logs are now cached in state (_rawLogs).
//  • Sorting & Deletions now execute instantly by re-processing the
//    local cache (_processLogs) instead of hitting the DB.
//  • _isAnomaly() fallbacks to sensible ranges if config is missing.
//  • Clear-All flows correctly through the new state manager.
//
//  IMPORTANT: filter values ('Всі', 'Температура', 'Вологість') remain
//  Ukrainian literals because db_service.dart matches them exactly.
// =====================================================================

import 'settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'db_service.dart';
import 'export_service.dart';
import 'theme/neo_brutalist_theme.dart';
import 'widgets/neo_widgets.dart';
import 'app_state.dart';

const double _kFallbackTempMin = 10.0;
const double _kFallbackTempMax = 30.0;
const double _kFallbackHumMin = 30.0;
const double _kFallbackHumMax = 70.0;

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final DbService _dbService = DbService();
  final SettingsService _settings = SettingsService(); 

  String _selectedType = 'Всі';
  String _searchDate = '';
  bool _isAscending = false;

  // КЕШУВАННЯ ДАНИХ (Вирішення проблеми з FutureBuilder)
  List<Map<String, dynamic>>? _rawLogs;
  Map<String, List<Map<String, dynamic>>>? _groupedLogs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _settings.load().then((_) {
      if (mounted) setState(() {}); 
    });
    _fetchLogs(); // Первинне завантаження
  }

  // Завантажує дані з БД (тільки при зміні фільтрів або Refresh)
  Future<void> _fetchLogs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final logs = await _dbService.getLogs(type: _selectedType, date: _searchDate);
    
    if (!mounted) return;
    _rawLogs = logs;
    _processLogs();
  }

  // Перераховує сортування та групування локально (без запитів до БД)
  void _processLogs() {
    if (_rawLogs == null) return;
    
    List<Map<String, dynamic>> logs = List.from(_rawLogs!);
    
    if (_isAscending) {
      logs = logs.reversed.toList();
    }
    
    _groupedLogs = _groupLogsByDate(logs);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupLogsByDate(List<Map<String, dynamic>> logs) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var log in logs) {
      final DateTime date = DateTime.parse(log['timestamp']);
      final String dayKey = DateFormat('yyyy-MM-dd').format(date);
      grouped.putIfAbsent(dayKey, () => []);
      grouped[dayKey]!.add(log);
    }
    return grouped;
  }

  String _formatHeaderDate(String dateStr) {
    final DateTime date = DateTime.parse(dateStr);
    final DateTime now = DateTime.now();
    if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(now)) {
      return t('today');
    }
    return DateFormat('d MMMM, yyyy').format(date);
  }

  Future<void> _exportCurrentView() async {
    if (_rawLogs != null && _rawLogs!.isNotEmpty) {
      await ExportService.exportLogsToCSV(_rawLogs!);
    }
  }

  bool _isAnomaly(String type, num value) {
    final v = value.toDouble();
    if (type == 'temp') {
      final cfgMin = _settings.tempMin;
      final cfgMax = _settings.tempMax;
      if (cfgMin >= cfgMax) {
        return v < _kFallbackTempMin || v > _kFallbackTempMax;
      }
      return v < cfgMin || v > cfgMax;
    } else {
      final cfgMin = _settings.humMin;
      final cfgMax = _settings.humMax;
      if (cfgMin >= cfgMax) {
        return v < _kFallbackHumMin || v > _kFallbackHumMax;
      }
      return v < cfgMin || v > cfgMax;
    }
  }

  Future<void> _confirmAndClearAll() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => _BrutalistConfirmDialog(
        title: t('confirm_delete_title'),
        message: t('confirm_delete_msg'),
        cancelLabel: t('cancel'),
        confirmLabel: t('confirm_delete'),
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    await _dbService.clearLogs();
    if (!mounted) return;

    // Очищаємо локальний кеш миттєво
    _rawLogs?.clear();
    _processLogs();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: NB.ink,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.trash2, color: NB.neonYellow, size: 18),
            const SizedBox(width: 10),
            Text(
              t('all_logs_cleared'),
              style: NB.label(12, color: NB.neonYellow, weight: FontWeight.w900),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: NB.ink, width: NB.borderThick),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NB.paper,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: Container(
          decoration: BoxDecoration(
            color: NB.paper,
            border: Border(bottom: BorderSide(color: NB.ink, width: NB.borderThick)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: NeoIconBox(
                      icon: LucideIcons.arrowLeft,
                      background: NB.white,
                      size: 48,
                      iconSize: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t('log_title'), 
                          style: NB.display(20),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('event_log_telemetry'),
                          style: NB.label(10.5, weight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    // Миттєве сортування локально
                    onTap: () {
                      _isAscending = !_isAscending;
                      _processLogs();
                    },
                    child: NeoIconBox(
                      icon: _isAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                      background: NB.neonYellow,
                      iconColor: Colors.black,
                      size: 44,
                      iconSize: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _exportCurrentView,
                    child: NeoIconBox(
                      icon: LucideIcons.download,
                      background: NB.mintGreen,
                      iconColor: Colors.black,
                      size: 44,
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              color: NB.ink,
              backgroundColor: NB.neonYellow,
              onRefresh: _fetchLogs,
              child: _buildListContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Виділено в окремий метод для чистоти build()
  Widget _buildListContent() {
    if (_isLoading || _groupedLogs == null) {
      return Center(
        child: CircularProgressIndicator(color: NB.ink, strokeWidth: 4),
      );
    }

    if (_rawLogs!.isEmpty) {
      // Використовуємо ListView, щоб RefreshIndicator працював навіть коли порожньо
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80), // Відступ для центрування
          _emptyState(),
        ],
      );
    }

    final dateKeys = _groupedLogs!.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final String dateKey = dateKeys[index];
        final List<Map<String, dynamic>> dayLogs = _groupedLogs![dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(dateKey, dayLogs.length),
            const SizedBox(height: 10),
            ...dayLogs.map((log) => _buildLogTile(log)),
            const SizedBox(height: 18),
          ],
        );
      },
    );
  }

  // ── FILTER BAR ─────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: NB.white,
        border: Border(bottom: BorderSide(color: NB.ink, width: NB.borderThick)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t('filter_by_type'),
                style: NB.label(10.5, weight: FontWeight.w900),
              ),
              const Spacer(),
              _buildClearAllButton(),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Всі', t('all'), LucideIcons.layers, NB.neonYellow,
                    selectedTextColor: Colors.black),
                const SizedBox(width: 10),
                _filterChip('Температура', t('temperature'), LucideIcons.thermometer, NB.neonYellow,
                    selectedTextColor: Colors.black),
                const SizedBox(width: 10),
                _filterChip('Вологість', t('humidity'), LucideIcons.droplets, NB.electricBlue,
                    selectedTextColor: Colors.white),
                const SizedBox(width: 16),
                Container(width: 2.5, height: 32, color: NB.ink),
                const SizedBox(width: 16),
                _buildDatePickerButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearAllButton() {
    return GestureDetector(
      onTap: _confirmAndClearAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: nbBlock(
          color: NB.hotRed,
          radius: 6,
          shadow: NB.hardShadowSm,
          borderWidth: NB.borderThin,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.trash2, size: 13, color: Colors.white),
            SizedBox(width: 6),
            _ClearAllLabel(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerButton() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2023),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: (NB.isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
              colorScheme: NB.isDark
                  ? const ColorScheme.dark(primary: Color(0xFFFF10F0), onPrimary: Colors.black)
                  : const ColorScheme.light(primary: Colors.black, onPrimary: Colors.white),
            ),
            child: child!,
          ),
        );
        if (date != null) {
          _searchDate = DateFormat('yyyy-MM-dd').format(date);
          _fetchLogs(); // Запит до БД
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: nbBlock(
          color: _searchDate.isEmpty ? NB.white : NB.mintGreen,
          radius: 6,
          shadow: NB.hardShadowSm,
          borderWidth: NB.borderThin,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendar,
                size: 14, color: _searchDate.isEmpty ? NB.ink : Colors.black),
            const SizedBox(width: 6),
            Text(
              _searchDate.isEmpty ? t('any_date') : _searchDate,
              style: NB.label(11,
                  weight: FontWeight.w900,
                  color: _searchDate.isEmpty ? NB.ink : Colors.black),
            ),
            if (_searchDate.isNotEmpty) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _searchDate = '';
                  _fetchLogs(); // Запит до БД
                },
                child: const Icon(LucideIcons.x, size: 14, color: Colors.black),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    String value,
    String displayLabel,
    IconData icon,
    Color color, {
    Color selectedTextColor = const Color(0xFF000000),
  }) {
    final bool selected = _selectedType == value;
    return GestureDetector(
      onTap: () {
        if (_selectedType != value) {
          _selectedType = value;
          _fetchLogs(); // Запит до БД
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: nbBlock(
          color: selected ? color : NB.white,
          radius: 6,
          shadow: selected ? NB.hardShadowSm : NB.hardShadowNone,
          borderWidth: NB.borderThin,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? selectedTextColor : NB.ink),
            const SizedBox(width: 6),
            Text(
              displayLabel.toUpperCase(),
              style: NB.label(
                11,
                weight: FontWeight.w900,
                color: selected ? selectedTextColor : NB.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DATE HEADER ───────────────────────────────────────────────
  Widget _buildDateHeader(String dateKey, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: nbBlock(
        color: NB.ink,
        radius: 4,
        shadow: NB.hardShadowSm,
        borderWidth: 0,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.calendar, size: 14, color: NB.neonYellow),
          const SizedBox(width: 8),
          Text(
            _formatHeaderDate(dateKey).toUpperCase(),
            style: NB.label(11, color: NB.paper, weight: FontWeight.w900),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: nbBlock(
              color: NB.neonYellow,
              radius: 2,
              shadow: NB.hardShadowNone,
              borderWidth: 0,
            ),
            child: Text(
              "$count ${t('entries')}",
              style: NB.label(9.5, weight: FontWeight.w900, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // ── LOG TILE ──────────────────────────────────────────────────
  Widget _buildLogTile(Map<String, dynamic> log) {
    final String type = log['type'];
    final num value = log['value'];
    final String time = DateFormat('HH:mm:ss').format(DateTime.parse(log['timestamp']));
    final bool isAnomaly = _isAnomaly(type, value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(log['id'].toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: nbBlock(color: NB.hotRed, shadow: NB.hardShadowNone),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t('delete'),
                  style: NB.label(12, color: Colors.white, weight: FontWeight.w900)),
              const SizedBox(width: 8),
              const Icon(LucideIcons.trash2, color: Colors.white, size: 22),
            ],
          ),
        ),
        onDismissed: (direction) async {
          await _dbService.deleteLog(log['id']);
          if (mounted) {
            // Миттєве оновлення кешу без запиту до БД
            _rawLogs?.removeWhere((e) => e['id'] == log['id']);
            _processLogs();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: NB.ink,
                content: Text(
                  t('record_deleted'),
                  style: NB.label(12, color: NB.neonYellow, weight: FontWeight.w900),
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: NB.ink, width: NB.borderThick),
                ),
                action: SnackBarAction(
                  label: t('snack_ok'),
                  textColor: NB.paper,
                  onPressed: () {},
                ),
              ),
            );
          }
        },
        child: Container(
          decoration: nbBlock(color: NB.white, shadow: NB.hardShadow),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: nbBlock(
                  color: type == 'temp' ? NB.neonYellow : NB.electricBlue,
                  radius: 6,
                  shadow: NB.hardShadowSm,
                  borderWidth: NB.borderThin,
                ),
                alignment: Alignment.center,
                child: Icon(
                  type == 'temp' ? LucideIcons.thermometer : LucideIcons.droplets,
                  size: 22,
                  color: type == 'temp' ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$value",
                          style: NB.mono(
                            22,
                            weight: FontWeight.w900,
                            color: isAnomaly ? NB.hotRed : NB.ink,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            type == 'temp' ? "°C" : "%",
                            style: NB.body(13, weight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (isAnomaly)
                          NeoTag.error(t('error'), icon: LucideIcons.triangleAlert)
                        else
                          NeoTag.info(t('info'), icon: LucideIcons.check),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type == 'temp' ? t('temperature_label') : t('humidity_label'),
                      style: NB.label(10, weight: FontWeight.w800, color: NB.mutedInk),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: nbBlock(
                  color: NB.ink,
                  radius: 3,
                  shadow: NB.hardShadowNone,
                  borderWidth: 0,
                ),
                child: Text(
                  time,
                  style: NB.mono(11, color: NB.neonYellow, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── EMPTY STATE ──────────────────────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(28),
        decoration: nbBlock(color: NB.white, shadow: NB.hardShadow),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: nbBlock(
                color: NB.electricBlue,
                radius: 6,
                shadow: NB.hardShadowSm,
                borderWidth: NB.borderThin,
              ),
              child: const Icon(LucideIcons.clipboardList, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(t('no_records'), style: NB.display(20)),
            const SizedBox(height: 8),
            Text(
              t('records_appear'),
              style: NB.body(13, color: NB.mutedInk),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearAllLabel extends StatelessWidget {
  const _ClearAllLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      t('clear_all'),
      style: NB.label(11, weight: FontWeight.w900, color: Colors.white),
    );
  }
}

class _BrutalistConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;

  const _BrutalistConfirmDialog({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: nbBlock(
          color: NB.white,
          radius: NB.radiusChunky,
          shadow: NB.hardShadowLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: nbBlock(
                    color: NB.hotRed,
                    radius: 6,
                    shadow: NB.hardShadowSm,
                    borderWidth: NB.borderThin,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.triangleAlert, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: NB.display(15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: NB.body(13, color: NB.mutedInk, weight: FontWeight.w600),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: NeoButton(
                    color: NB.white,
                    textColor: NB.ink,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Center(
                      child: Text(cancelLabel),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeoButton(
                    color: NB.hotRed,
                    textColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.trash2, size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              confirmLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}