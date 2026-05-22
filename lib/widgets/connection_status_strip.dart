import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../mqtt_service.dart';
import '../theme/neo_brutalist_theme.dart';
import '../app_state.dart';

class ConnectionStatusStrip extends StatelessWidget {
  final MqttService mqtt;

  const ConnectionStatusStrip({super.key, required this.mqtt});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MqttConnectionState>(
      stream: mqtt.stateStream,
      initialData: MqttConnectionState.disconnected,
      builder: (context, snapshot) {
        final state = snapshot.data ?? MqttConnectionState.disconnected;

        Color bgColor;
        String text;
        IconData icon;
        Color contentColor = Colors.black;

        // Визначаємо стиль залежно від стану підключення
        switch (state) {
          case MqttConnectionState.connected:
            bgColor = NB.mintGreen;
            text = t('connected');
            icon = LucideIcons.checkCircle2;
            break;
          case MqttConnectionState.connecting:
            bgColor = NB.neonYellow;
            text = t('connecting');
            icon = LucideIcons.refreshCw;
            break;
          case MqttConnectionState.error:
            bgColor = NB.hotRed;
            text = t('connection_error');
            icon = LucideIcons.triangleAlert;
            contentColor = Colors.white; 
            break;
          case MqttConnectionState.disconnected:
            // Видалили `default:`, залишили лише конкретний case
            bgColor = NB.white;
            text = t('disconnected');
            icon = LucideIcons.xCircle;
            break;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: nbBlock(
            color: bgColor,
            shadow: NB.hardShadowSm,
            radius: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: contentColor),
              const SizedBox(width: 8),
              Text(
                text.toUpperCase(),
                style: NB.label(
                  11, 
                  weight: FontWeight.w900, 
                  color: contentColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}