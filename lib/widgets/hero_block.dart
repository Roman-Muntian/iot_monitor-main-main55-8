// =====================================================================
//  HERO BLOCK — ВИПРАВЛЕНО ДЛЯ LUCIDE_ICONS_FLUTTER
// =====================================================================

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart'; // ОНОВЛЕНО

import '../app_state.dart';
import '../theme/neo_brutalist_theme.dart';
import 'neo_widgets.dart';

class HeroBlock extends StatelessWidget {
  const HeroBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      color: NB.charcoal,
      borderColor: NB.ink,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      shadow: NB.hardShadowLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeoIconBox(
                icon: LucideIcons.cpu, // Виправлено через новий імпорт
                background: NB.mintGreen,
                size: 40,
                iconSize: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "ROMAN 41-КІ",
                  style: NB.display(15, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // У NeoTag іконка передається як IconData, тому працює без помилок
              NeoTag.success(t('live'), icon: LucideIcons.radio),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            t('real_time_telemetry'),
            style: NB.label(11, color: NB.neonYellow, weight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            t('realtime_subtitle'),
            style: NB.body(12.5,
                color: const Color(0xFFC9C9C9), weight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}