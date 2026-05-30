// =====================================================================
//  ANALYTICS SCREEN — ОПТИМІЗОВАНО
//  1. getLogs() з лімітом 200 замість усіх записів
//  2. _isAnomaly кешується щоб не рахувати двічі
//  3. KPI обчислення винесені з build() у _fetchData()
//     щоб не рахувати при кожній перебудові
// =====================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'db_service.dart';
import 'theme/neo_brutalist_theme.dart';
import 'widgets/neo_primitives.dart';
import 'app_state.dart';

// ── Кешовані результати обчислень ──────────────────────────────────
class _ChartData {
  final List<FlSpot> tempPoints;
  final List<FlSpot> humPoints;
  final List<Map<String, dynamic>> tempLogs;
  final double minY;
  final double maxY;
  final double tempLast;
  final double humLast;
  final double tempAvg;
  final double humAvg;

  const _ChartData({
    required this.tempPoints,
    required this.humPoints,
    required this.tempLogs,
    required this.minY,
    required this.maxY,
    required this.tempLast,
    required this.humLast,
    required this.tempAvg,
    required this.humAvg,
  });
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DbService _dbService = DbService();

  _ChartData? _chartData; // ← кешовані обчислення
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchData();
    });
  }

  // ← ОПТИМІЗАЦІЯ: всі обчислення тут, а не в build()
  Future<void> _fetchData() async {
    // ОПТИМІЗАЦІЯ 5: ліміт 200 замість усіх записів
    final logs = await _dbService.getLogs(limit: 200);

    if (!mounted) return;

    if (logs.isEmpty) {
      setState(() {
        _chartData = null;
        _loading = false;
      });
      return;
    }

    // Обчислюємо один раз при завантаженні даних
    final tempLogs = logs
        .where((e) => e['type'] == 'temp')
        .take(20)
        .toList()
        .reversed
        .toList();
    final humLogs = logs
        .where((e) => e['type'] == 'hum')
        .take(20)
        .toList()
        .reversed
        .toList();

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    final tempPoints = <FlSpot>[];
    for (int i = 0; i < tempLogs.length; i++) {
      final double val = (tempLogs[i]['value'] as num).toDouble();
      tempPoints.add(FlSpot(i.toDouble(), val));
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
    }

    final humPoints = <FlSpot>[];
    for (int i = 0; i < humLogs.length; i++) {
      final double val = (humLogs[i]['value'] as num).toDouble();
      humPoints.add(FlSpot(i.toDouble(), val));
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
    }

    if (minY == double.infinity) {
      minY = 0;
      maxY = 100;
    } else {
      minY = (minY - 5).clamp(0, double.infinity);
      maxY += 5;
    }

    final tempLast = tempPoints.isNotEmpty ? tempPoints.last.y : 0.0;
    final humLast = humPoints.isNotEmpty ? humPoints.last.y : 0.0;
    final tempAvg = tempPoints.isEmpty
        ? 0.0
        : tempPoints.map((e) => e.y).reduce((a, b) => a + b) /
            tempPoints.length;
    final humAvg = humPoints.isEmpty
        ? 0.0
        : humPoints.map((e) => e.y).reduce((a, b) => a + b) /
            humPoints.length;

    setState(() {
      _loading = false;
      _chartData = _ChartData(
        tempPoints: tempPoints,
        humPoints: humPoints,
        tempLogs: tempLogs,
        minY: minY,
        maxY: maxY,
        tempLast: tempLast,
        humLast: humLast,
        tempAvg: tempAvg,
        humAvg: humAvg,
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
            border: Border(
                bottom: BorderSide(color: NB.ink, width: NB.borderThick)),
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
                        Text(t('analytics_title'), style: NB.display(20)),
                        const SizedBox(height: 4),
                        Text(
                          t('last_samples'),
                          style: NB.label(10.5, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  NeoIconBox(
                    icon: LucideIcons.chartBar,
                    background: NB.mintGreen,
                    iconColor: Colors.black,
                    size: 48,
                    iconSize: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: NB.ink, strokeWidth: 4),
      );
    }

    if (_chartData == null) return _emptyState();

    final d = _chartData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _kpiTile(
                  t('temp_now'),
                  "${d.tempLast.toStringAsFixed(1)}°C",
                  NB.neonYellow,
                  LucideIcons.thermometer,
                  textColor: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiTile(
                  t('hum_now'),
                  "${d.humLast.toStringAsFixed(1)}%",
                  NB.electricBlue,
                  LucideIcons.droplets,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _kpiTile(
                  t('temp_avg'),
                  "${d.tempAvg.toStringAsFixed(1)}°C",
                  NB.white,
                  LucideIcons.activity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiTile(
                  t('hum_avg'),
                  "${d.humAvg.toStringAsFixed(1)}%",
                  NB.mintGreen,
                  LucideIcons.activity,
                  textColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ── CHART CARD ──
          Container(
            height: 380,
            padding: const EdgeInsets.fromLTRB(8, 22, 22, 14),
            decoration: nbBlock(color: NB.white, shadow: NB.hardShadow),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 4, bottom: 14),
                  child: Row(
                    children: [
                      Text(t('timeline'), style: NB.display(13)),
                      const Spacer(),
                      _legendItem(t('temp_short'), NB.neonYellow),
                      const SizedBox(width: 10),
                      _legendItem(t('hum_short'), NB.electricBlue),
                    ],
                  ),
                ),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: d.minY,
                      maxY: d.maxY,
                      clipData: const FlClipData.all(),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(color: NB.ink, width: NB.borderThick),
                          bottom: BorderSide(color: NB.ink, width: NB.borderThick),
                          top: BorderSide(color: NB.ink, width: 0),
                          right: BorderSide(color: NB.ink, width: 0),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 0,
                          tooltipBorder:
                              BorderSide(color: NB.ink, width: NB.borderThin),
                          tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          getTooltipColor: (_) => NB.white,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final isTemp = spot.barIndex == 0;
                              return LineTooltipItem(
                                "${spot.y.toStringAsFixed(1)} ${isTemp ? '°C' : '%'}",
                                NB.mono(13,
                                    weight: FontWeight.w900,
                                    color: isTemp ? NB.ink : NB.electricBlue),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: d.tempPoints,
                          isCurved: false,
                          color: NB.ink,
                          barWidth: 4,
                          isStrokeCapRound: false,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, __, ___, ____) =>
                                FlDotCirclePainter(
                              radius: 4.5,
                              color: NB.neonYellow,
                              strokeWidth: 2,
                              strokeColor: NB.ink,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: NB.neonYellow.withValues(alpha: 0.45),
                          ),
                        ),
                        LineChartBarData(
                          spots: d.humPoints,
                          isCurved: false,
                          color: NB.electricBlue,
                          barWidth: 4,
                          isStrokeCapRound: false,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, __, ___, ____) =>
                                FlDotCirclePainter(
                              radius: 4.5,
                              color: NB.white,
                              strokeWidth: 2,
                              strokeColor: NB.electricBlue,
                            ),
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: d.tempLogs.isEmpty
                                ? 1
                                : (d.tempLogs.length / 5).ceilToDouble(),
                            getTitlesWidget: (value, meta) {
                              final int index = value.toInt();
                              if (index >= 0 && index < d.tempLogs.length) {
                                final DateTime time = DateTime.parse(
                                    d.tempLogs[index]['timestamp']);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('HH:mm').format(time),
                                    style:
                                        NB.label(10, weight: FontWeight.w800),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  value.toInt().toString(),
                                  style: NB.label(10, weight: FontWeight.w800),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: nbBlock(
              color: NB.neonYellow,
              radius: 4,
              borderWidth: NB.borderThin,
              shadow: NB.hardShadowSm,
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: Colors.black),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    // Якщо t() не const — прибрати const з Row
                    'Натисніть на точку графіка для деталей',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                color: NB.neonYellow,
                radius: 6,
                shadow: NB.hardShadowSm,
                borderWidth: NB.borderThin,
              ),
              child: const Icon(LucideIcons.chartBar,
                  size: 36, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Text(t('no_data_yet'), style: NB.display(20)),
            const SizedBox(height: 8),
            Text(
              t('waiting_telemetry'),
              style: NB.body(13, color: NB.mutedInk),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiTile(
    String label,
    String value,
    Color color,
    IconData icon, {
    Color? textColor,
  }) {
    final tc = textColor ?? NB.ink;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: nbBlock(color: color, shadow: NB.hardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: tc),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: NB.label(10.5, color: tc, weight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: NB.mono(28, color: tc, weight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: nbBlock(
            color: color,
            radius: 0,
            shadow: NB.hardShadowNone,
            borderWidth: 2,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: NB.label(11, weight: FontWeight.w900)),
      ],
    );
  }
}