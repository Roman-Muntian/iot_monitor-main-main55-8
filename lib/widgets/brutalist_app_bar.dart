import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app_state.dart';
import '../mqtt_service.dart';
import '../theme/neo_brutalist_theme.dart';
import 'neo_widgets.dart';

class BrutalistAppBar extends StatelessWidget implements PreferredSizeWidget {
  final MqttService mqtt;
  // ← ОПТИМІЗАЦІЯ: отримуємо стан як параметр, без StreamBuilder
  final MqttConnectionState connectionState;

  const BrutalistAppBar({
    super.key,
    required this.mqtt,
    required this.connectionState,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NB.paper,
        border: Border(bottom: BorderSide(color: NB.ink, width: NB.borderThick)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: NeoIconBox(
                    icon: LucideIcons.menu,
                    background: NB.white,
                    size: 48,
                    iconSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'KlimaBox',
                      style: NB.display(20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _ConnectionStatus(state: connectionState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  // ← отримуємо стан напряму, StreamBuilder прибрано
  final MqttConnectionState state;
  const _ConnectionStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    String? label;

    if (state == MqttConnectionState.connected) {
      color = NB.mintGreen;
      label = null;
    } else if (state == MqttConnectionState.error) {
      color = NB.hotRed;
      label = null;
    } else {
      color = const Color(0xFF8A8A8A);
      label = t('connecting');
    }

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: NB.ink, width: 1.5),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 8),
          Text(
            label,
            style: NB.label(10.5, color: NB.ink, weight: FontWeight.w800),
          ),
        ],
      ],
    );
  }
}