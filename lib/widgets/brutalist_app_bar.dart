import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../mqtt_service.dart';
import '../theme/neo_brutalist_theme.dart';
import 'neo_widgets.dart';

class BrutalistAppBar extends StatelessWidget implements PreferredSizeWidget {
  final MqttService mqtt;
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
                child: Text(
                  'KlimaBox',
                  style: NB.display(28), // ← більший розмір
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}