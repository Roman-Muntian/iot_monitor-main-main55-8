// =====================================================================
//  SENSOR CARD  (extracted from main.dart)
//  Identical visuals & logic — animated value, alarm header swap,
//  navigation to AnalyticsScreen on tap.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../analytics_screen.dart';
import '../app_state.dart';
import '../theme/neo_brutalist_theme.dart';
import 'neo_widgets.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String unit;
  final Stream<String> stream;
  final Color accent;
  final IconData icon;
  final double min;
  final double max;

  const SensorCard({
    super.key,
    required this.title,
    required this.unit,
    required this.stream,
    required this.accent,
    required this.icon,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: stream,
      builder: (context, snap) {
        final double val = double.tryParse(snap.data ?? '0') ?? 0;
        final bool alarm = (val < min || val > max) && snap.hasData;
        final Color headerColor = alarm ? NB.hotRed : accent;
        final Color headerText = (headerColor == NB.electricBlue ||
                headerColor == NB.hotRed)
            ? Colors.white
            : Colors.black;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AnalyticsScreen()),
            );
          },
          child: Container(
            decoration: nbBlock(color: NB.white, shadow: NB.hardShadow),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Vibrant unique header strip ──
                Container(
                  decoration: BoxDecoration(
                    color: headerColor,
                    border: Border(
                      bottom:
                          BorderSide(color: NB.ink, width: NB.borderThick),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(icon, size: 22, color: headerText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: NB.display(14, color: headerText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (alarm)
                        NeoTag.error(t('alarm'),
                            icon: LucideIcons.alertTriangle)
                      else
                        NeoTag(
                          label: t('ok'),
                          color: NB.ink,
                          textColor: NB.paper,
                          icon: LucideIcons.check,
                        ),
                    ],
                  ),
                ),
                // ── Body: oversized value ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: val),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedVal, _) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.bottomLeft,
                                  child: Text(
                                    snap.hasData
                                        ? animatedVal.toStringAsFixed(1)
                                        : "--",
                                    style: NB.mono(
                                      78,
                                      weight: FontWeight.w900,
                                      color: alarm ? NB.hotRed : NB.ink,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  unit,
                                  style: NB.display(22, color: NB.ink),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      // Range indicator
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: nbBlock(
                              color: NB.subtleGrey,
                              radius: 4,
                              shadow: NB.hardShadowNone,
                              borderWidth: NB.borderThin,
                            ),
                            child: Text(
                              "${t('target')} ${min.round()}–${max.round()}$unit",
                              style: NB.label(10, weight: FontWeight.w900),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            t('tap_for_analytics'),
                            style: NB.label(10,
                                color: NB.mutedInk, weight: FontWeight.w800),
                          ),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.chevronRight,
                              size: 16, color: NB.ink),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
