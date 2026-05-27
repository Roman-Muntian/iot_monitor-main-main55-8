import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    // ListenableBuilder реагує на зміну мови в AppState
    return ListenableBuilder(
      listenable: AppState.instance, 
      builder: (context, _) {
        return StreamBuilder<String>(
          stream: stream,
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final double val = double.tryParse(snap.data!) ?? 0;
            
            // Тепер checkAlarm має повертати ключ помилки (напр: 'temp_low', 'hum_high') 
            // АБО null, якщо все в нормі.
            final String? alarmKey = mqtt.settings.checkAlarm(val, type);
            if (alarmKey == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: nbBlock(color: NB.hotRed, shadow: NB.hardShadow, radius: 8),
              child: Row(
                children: [
                  const Icon(LucideIcons.triangleAlert, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _buildLocalizedMessage(alarmKey, val, type),
                      style: NB.body(13, color: Colors.white, weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  // Надійний маппінг системних ключів у локалізований текст
  String _buildLocalizedMessage(String alarmKey, double value, String type) {
    // Припускаємо, що checkAlarm тепер повертає ключі: 
    // 'temp_low', 'temp_high', 'hum_low', 'hum_high'
    
    String localizedPrefix = '';
    
    switch (alarmKey) {
      case 'temp_low':
        localizedPrefix = t('temp_too_low');
        break;
      case 'temp_high':
        localizedPrefix = t('temp_too_high');
        break;
      case 'hum_low':
        localizedPrefix = t('hum_too_low');
        break;
      case 'hum_high':
        localizedPrefix = t('hum_too_high');
        break;
      default:
        localizedPrefix = alarmKey; // Fallback
    }

    final unit = type == 'temp' ? '°C' : '%';
    return '$localizedPrefix: ${value.toStringAsFixed(1)}$unit';
  }
}