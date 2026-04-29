// =====================================================================
//  LAST UPDATE BLOCK  (extracted from main.dart)
//  Tiny pill that shows the most recent telemetry timestamp.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app_state.dart';
import '../theme/neo_brutalist_theme.dart';

class LastUpdateBlock extends StatelessWidget {
  /// Pre-formatted timestamp string ("HH:mm:ss") or "--:--:--".
  final String time;

  const LastUpdateBlock({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: nbBlock(
        color: NB.neonYellow,
        radius: 4,
        shadow: NB.hardShadowSm,
        borderWidth: NB.borderThin,
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.clock, size: 16, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            t('last_update'),
            style: NB.label(11, weight: FontWeight.w900, color: Colors.black),
          ),
          const Spacer(),
          Text(
            time,
            style: NB.mono(15, weight: FontWeight.w800, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
