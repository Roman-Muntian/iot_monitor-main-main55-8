import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart'; // ОНОВЛЕНО

import '../app_state.dart';
import '../mqtt_service.dart';
import '../theme/neo_brutalist_theme.dart';

class AlarmOverlay extends StatelessWidget {
  final MqttService mqtt;
  const AlarmOverlay({super.key, required this.mqtt});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AlarmBanner(type: 'temp', stream: mqtt.tempStream, mqtt: mqtt),
            _AlarmBanner(type: 'hum', stream: mqtt.humStream, mqtt: mqtt),
          ],
        ),
      ),
    );
  }
}

class _AlarmBanner extends StatelessWidget {
  final String type;
  final Stream<String> stream;
  final MqttService mqtt;

  const _AlarmBanner({required this.type, required this.stream, required this.mqtt});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final double val = double.tryParse(snap.data!) ?? 0;
        final String? msg = mqtt.settings.checkAlarm(val, type);
        if (msg == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: nbBlock(color: NB.hotRed, shadow: NB.hardShadow, radius: 8),
          child: Row(
            children: [
              const Icon(LucideIcons.triangleAlert, color: Colors.white, size: 24), // ВИДАЛЕНО const
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _localizeAlarm(msg, type),
                  style: NB.body(13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _localizeAlarm(String original, String type) {
  final colon = original.indexOf(':');
  final tail = colon >= 0 ? original.substring(colon) : '';
  if (type == 'temp') {
    if (original.contains('занизька')) return '${t('temp_too_low')}$tail';
    if (original.contains('зависока')) return '${t('temp_too_high')}$tail';
  } else if (type == 'hum') {
    if (original.contains('занизька')) return '${t('hum_too_low')}$tail';
    if (original.contains('зависока')) return '${t('hum_too_high')}$tail';
  }
  return original;
}