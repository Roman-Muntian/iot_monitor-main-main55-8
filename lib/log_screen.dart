// =====================================================================
//  LOG SCREEN — NEO-BRUTALIST EVENT LOG
//
//  Logic preserved: filter chips, date filter, dismiss-to-delete,
//  ascending toggle, CSV export — all unchanged.
//
//  ── ISSUE FIXES (Jan 2026) ──
//  • _isAnomaly():  defaults from MqttService can be 20.0/20.0
//                   (min == max), which made every reading look anomalous.
//                   Now falls back to a sensible household range
//                   (Temp 10–30 °C, Humidity 30–70 %) when the user has
//                   not yet configured the limits.
//  • Clear-All:     a chunky Brutalist "ОЧИСТИТИ / CLEAR ALL" button is
//                   placed in the filter-bar header row (Spacer keeps it
//                   right-aligned and overflow-safe on small screens).
//                   Tapping it shows a Brutalist confirmation Dialog;
//                   on confirm → DbService.clearLogs() + Brutalist SnackBar.
//
//  IMPORTANT: filter values ('Всі', 'Температура', 'Вологість') remain
//  Ukrainian literals because db_service.dart matches them exactly.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'db_service.dart';
import 'export_service.dart';
import 'mqtt_service.dart';
import 'theme/neo_brutalist_theme.dart';
import 'widgets/neo_widgets.dart';
import 'app_state.dart';

/// Sensible household fallback ranges, used when the user-configured
/// thresholds in MqttService.settings are unset / invalid (min >= max).
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
  // ── Logic preserved ─────────────────────────────────────────────
  final DbService _dbService = DbService();
  final MqttService _mqtt = MqttService();

  String _selectedType = 'Всі';
  String _searchDate = '';
  bool _isAscending = false;

  Map<String, List<Map<String, dynamic>>> _groupLogsByDate(
      List<Map<String, dynamic>> logs) {
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
    final logs =
        await _dbService.getLogs(type: _selectedType, date: _searchDate);
    if (logs.isNotEmpty) {
      await ExportService.exportLogsToCSV(logs);
    }
  }
  // ──────────────────────────────────────────────────────────────────

  // ── ANOMALY CHECK (FIX FOR ISSUE #1) ──────────────────────────────
  // Returns true ONLY when the value is outside the user's configured
  // range.  If the configured range is degenerate (min >= max — e.g. the
  // app's first launch, when SettingsService defaults to 20/20), we fall
  // back to a sensible household range so normal readings are not falsely
  // flagged as anomalies.
  bool _isAnomaly(String type, num value) {
    final v = value.toDouble();
    if (type == 'temp') {
      final cfgMin = _mqtt.settings.tempMin;
      final cfgMax = _mqtt.settings.tempMax;
      if (cfgMin >= cfgMax) {
        return v < _kFallbackTempMin || v > _kFallbackTempMax;
      }
      return v < cfgMin || v > cfgMax;
    } else {
      final cfgMin = _mqtt.settings.humMin;
      final cfgMax = _mqtt.settings.humMax;
      if (cfgMin >= cfgMax) {
        return v < _kFallbackHumMin || v > _kFallbackHumMax;
      }
      return v < cfgMin || v > cfgMax;
    }
  }

  // ── CLEAR-ALL FLOW (FIX FOR ISSUE #2) ─────────────────────────────
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
              style: NB.label(12,
                  color: NB.neonYellow, weight: FontWeight.w900),
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NB.paper,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            color: NB.paper,
            border: Border(bottom: BorderSide(color: NB.ink, width: NB.borderThick)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        Text(t('log_title'), style: NB.display(20)),
                        const SizedBox(height: 4),
                        Text(
                          t('event_log_telemetry'),
                          style: NB.label(10.5, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isAscending = !_isAscending),
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
              onRefresh: () async => setState(() {}),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _dbService.getLogs(type: _selectedType, date: _searchDate),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: NB.ink, strokeWidth: 4),
                    );
                  }

                  var logs = snapshot.data!;
                  if (_isAscending) logs = logs.reversed.toList();

                  if (logs.isEmpty) return _emptyState();

                  final groupedLogs = _groupLogsByDate(logs);
                  final dateKeys = groupedLogs.keys.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: dateKeys.length,
                    itemBuilder: (context, index) {
                      final String dateKey = dateKeys[index];
                      final List<Map<String, dynamic>> dayLogs = groupedLogs[dateKey]!;

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
                },
              ),
            ),
          ),
        ],
      ),
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
          // Header row: "FILTER BY TYPE"  +  "CLEAR ALL"
          // Spacer() pushes the destructive action to the far right and
          // keeps the row overflow-safe on narrow screens.
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
                // Filter VALUE stays in Ukrainian (matches DB query); only
                // the visible LABEL is translated.
                _filterChip('Всі', t('all'), LucideIcons.layers, NB.neonYellow,
                    selectedTextColor: Colors.black),
                const SizedBox(width: 10),
                _filterChip(
                    'Температура', t('temperature'), LucideIcons.thermometer, NB.neonYellow,
                    selectedTextColor: Colors.black),
                const SizedBox(width: 10),
                _filterChip(
                    'Вологість', t('humidity'), LucideIcons.droplets, NB.electricBlue,
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

  // ── CLEAR-ALL BUTTON (compact, right-aligned in header row) ──────
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(LucideIcons.trash2, size: 13, color: Colors.white),
            SizedBox(width: 6),
            _ClearAllLabel(),
          ],
        ),
      ),
    );
  }

  // ── DATE PICKER BUTTON (extracted for readability) ────────────────
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
                  ? const ColorScheme.dark(
                      primary: Color(0xFFFF10F0),
                      onPrimary: Colors.black,
                    )
                  : const ColorScheme.light(
                      primary: Colors.black,
                      onPrimary: Colors.white,
                    ),
            ),
            child: child!,
          ),
        );
        if (date != null) {
          setState(() => _searchDate = DateFormat('yyyy-MM-dd').format(date));
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
                onTap: () => setState(() => _searchDate = ''),
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
      onTap: () => setState(() => _selectedType = value),
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

  // ── LOG TILE (Dismissible preserved) ──────────────────────────
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
            setState(() {});
          }
        },
        child: Container(
          decoration: nbBlock(color: NB.white, shadow: NB.hardShadow),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              // Icon block — typed color
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
              // Value + label
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
                          NeoTag.error(t('error'), icon: LucideIcons.alertTriangle)
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
              // Time pill
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

// ─────────────────────────────────────────────────────────────────────
// Tiny stateless helper so the Clear-All label rebuilds whenever
// AppState (language) changes — kept inline because it is purely visual
// and has no business logic.
// ─────────────────────────────────────────────────────────────────────
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

// =====================================================================
//  BRUTALIST CONFIRM DIALOG  (shown by _confirmAndClearAll)
//  Hard borders, hard shadow, no rounded corners on the surface.
//  Two NeoButton actions: Cancel (white) + Delete (red).
// =====================================================================
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
                  child: const Icon(LucideIcons.alertTriangle,
                      size: 22, color: Colors.white),
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
            // Two buttons — kept in a Row with Expanded children so they
            // never overflow on narrow screens.
            Row(
              children: [
                Expanded(
                  child: NeoButton(
                    color: NB.white,
                    textColor: NB.ink,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
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
