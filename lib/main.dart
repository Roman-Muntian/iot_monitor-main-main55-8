// =====================================================================
//  IoT MONITOR — NEO-BRUTALIST DASHBOARD
//  All MQTT / DB / Settings logic is preserved verbatim — only the
//  visual layer (decorations, typography, colors, shadows) was rebuilt.
//
//  ── ADDITIONS ──
//  * Localization (UK / EN) — see `lib/i18n/app_strings.dart`
//  * Light / Dark Neo-Brutalist theme — see `lib/theme/neo_brutalist_theme.dart`
//  * Both preferences persisted via shared_preferences (AppState.load)
//  * Cyrillic-capable font fallbacks (Unbounded / Manrope / JetBrains Mono)
//
//  ── REFACTOR ──
//  Heavy UI chunks were extracted into `lib/widgets/`:
//    BrutalistAppBar, HeroBlock, SensorCard, LastUpdateBlock,
//    DashboardDrawer, AlarmOverlay, BrutalistRangeSlider,
//    BrutalistToggle, settings_sheet.showSettingsSheet().
//  No MQTT / DB / export / simulator logic was touched.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_state.dart';
import 'db_service.dart';
import 'export_service.dart';
import 'mqtt_service.dart';
import 'theme/neo_brutalist_theme.dart';

import 'widgets/alarm_overlay.dart';
import 'widgets/brutalist_app_bar.dart';
import 'widgets/dashboard_drawer.dart';
import 'widgets/hero_block.dart';
import 'widgets/last_update_block.dart';
import 'widgets/sensor_card.dart';
import 'widgets/settings_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load persisted language + theme BEFORE building the tree, so the
  // first paint already reflects the user's saved preference.
  await AppState.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the entire tree whenever language or theme changes.
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: NB.isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: NB.paper,
            textTheme: TextTheme(
              bodyMedium: NB.body(14),
              bodyLarge: NB.body(16),
              titleLarge: NB.display(20),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: NB.paper,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: NB.ink),
            ),
            colorScheme: NB.isDark
                ? ColorScheme.dark(
                    primary: NB.electricBlue,
                    secondary: NB.mintGreen,
                    surface: NB.white,
                  )
                : ColorScheme.light(
                    primary: NB.electricBlue,
                    secondary: NB.mintGreen,
                    surface: NB.white,
                  ),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ),
          home: const Dashboard(),
        );
      },
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // ── Logic preserved verbatim ─────────────────────────────────────
  final MqttService mqtt = MqttService();
  final DbService _dbService = DbService();
  String _lastUpdate = "--:--:--";

  @override
  void initState() {
    super.initState();
    mqtt.connect();
    mqtt.tempStream.listen((_) => _updateTime());
    mqtt.humStream.listen((_) => _updateTime());
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _lastUpdate = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
  }

  Future<void> _exportData() async {
    final allLogs = await _dbService.getLogs();
    if (allLogs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('log_empty_msg'))),
        );
      }
      return;
    }
    await ExportService.exportLogsToCSV(allLogs);
  }
  // ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NB.paper,
      appBar: BrutalistAppBar(mqtt: mqtt),
      drawer: DashboardDrawer(
        onOpenSettings: () => showSettingsSheet(context, mqtt),
        onExport: _exportData,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HeroBlock(),
                const SizedBox(height: 24),
                SensorCard(
                  title: t('temperature'),
                  unit: "°C",
                  stream: mqtt.tempStream,
                  accent: NB.neonYellow,
                  icon: LucideIcons.thermometer,
                  min: mqtt.settings.tempMin,
                  max: mqtt.settings.tempMax,
                ),
                const SizedBox(height: 24),
                SensorCard(
                  title: t('humidity'),
                  unit: "%",
                  stream: mqtt.humStream,
                  accent: NB.electricBlue,
                  icon: LucideIcons.droplets,
                  min: mqtt.settings.humMin,
                  max: mqtt.settings.humMax,
                ),
                const SizedBox(height: 28),
                LastUpdateBlock(time: _lastUpdate),
                const SizedBox(height: 12),
              ],
            ),
          ),
          AlarmOverlay(mqtt: mqtt),
        ],
      ),
    );
  }
}
