import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_state.dart';
import 'db_service.dart';
import 'export_service.dart';
import 'mqtt_service.dart';
import 'theme/neo_brutalist_theme.dart';

import 'widgets/alarm_overlay.dart';
import 'widgets/app_bar.dart';
import 'widgets/connection_status_strip.dart';
import 'widgets/dashboard_drawer.dart';
import 'widgets/last_update_widget.dart';
import 'widgets/sensor_card.dart';
import 'widgets/settings_sheet.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final MqttService mqtt = MqttService();
  final DbService _dbService = DbService();
  String _lastUpdate = "--:--:--";

  MqttConnectionState _connectionState = MqttConnectionState.disconnected;

  @override
  void initState() {
    super.initState();
    mqtt.connect();
    mqtt.tempStream.listen((_) => _updateTime());
    mqtt.humStream.listen((_) => _updateTime());
    AppState.instance.addListener(_rebuildUI);

    mqtt.stateStream.listen((state) {
      if (mounted) setState(() => _connectionState = state);
    });
  }

  void _rebuildUI() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_rebuildUI);
    mqtt.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NB.paper,
      appBar: BrutalistAppBar(
        mqtt: mqtt,
        connectionState: _connectionState,
      ),
      drawer: DashboardDrawer(
        mqtt: mqtt,
        connectionState: _connectionState,
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
                ConnectionStatusStrip(connectionState: _connectionState),
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