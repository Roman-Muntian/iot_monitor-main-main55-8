// =====================================================================
//  DASHBOARD DRAWER — ВИПРАВЛЕНО ДЛЯ LUCIDE_ICONS_FLUTTER
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart'; // ОНОВЛЕНО

import '../analytics_screen.dart';
import '../app_state.dart';
import '../log_screen.dart';
import '../theme/neo_brutalist_theme.dart';
import 'neo_widgets.dart';

class DashboardDrawer extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onExport;

  const DashboardDrawer({
    super.key,
    required this.onOpenSettings,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: NB.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: NB.ink, width: NB.borderThick),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              decoration: BoxDecoration(
                color: NB.electricBlue,
                border: Border(
                    bottom: BorderSide(color: NB.ink, width: NB.borderThick)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NeoIconBox(
                        icon: LucideIcons.cpu, //
                        background: NB.neonYellow,
                        size: 52,
                        iconSize: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ROMAN 41-КІ",
                              style: NB.display(18, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            NeoTag.success(t('online'), icon: LucideIcons.signal),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('iot_system_active'),
                    style: NB.label(11,
                        color: Colors.white, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('streaming_telemetry'),
                    style: NB.body(12,
                        color: Colors.white, weight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // ── Items ────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(t('main_menu'),
                      style: NB.label(11, weight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  _DrawerItem(
                    title: t('limits_settings'),
                    subtitle: t('limits_settings_sub'),
                    icon: LucideIcons.slidersHorizontal, // ЗМІНЕНО: sliders -> slidersHorizontal
                    color: NB.neonYellow,
                    textColor: Colors.black,
                    onTap: () {
                      Navigator.pop(context);
                      onOpenSettings();
                    },
                  ),
                  const SizedBox(height: 14),
                  _DrawerItem(
                    title: t('event_log'),
                    subtitle: t('event_log_sub'),
                    icon: LucideIcons.clipboardList,
                    color: NB.electricBlue,
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LogScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _DrawerItem(
                    title: t('analytics'),
                    subtitle: t('analytics_sub'),
                    icon: LucideIcons.chartBar, // ЗМІНЕНО: barChart2 -> chartBar
                    color: NB.mintGreen,
                    textColor: Colors.black,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AnalyticsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  Container(height: 2.5, color: NB.ink),
                  const SizedBox(height: 22),
                  Text(t('export_section'),
                      style: NB.label(11, weight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  _DrawerItem(
                    title: t('download_csv'),
                    subtitle: t('download_csv_sub'),
                    icon: LucideIcons.cloudDownload, // ЗМІНЕНО: downloadCloud -> cloudDownload
                    color: NB.white,
                    onTap: () {
                      Navigator.pop(context);
                      onExport();
                    },
                  ),
                ],
              ),
            ),

            // ── Footer ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: NB.white,
                border: Border(
                    top: BorderSide(color: NB.ink, width: NB.borderThick)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.towerControl, size: 16, color: NB.ink), // ЗМІНЕНО: radioTower -> towerControl + видалено const
                  const SizedBox(width: 8),
                  Text(
                    t('iot_monitor_pro'),
                    style: NB.label(11, weight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Color? textColor;

  const _DrawerItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final tc = textColor ?? NB.ink;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: nbBlock(color: color, shadow: NB.hardShadow, radius: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: nbBlock(
                color: NB.white,
                radius: 4,
                shadow: NB.hardShadowNone,
                borderWidth: NB.borderThin,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: NB.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: NB.body(14, weight: FontWeight.w800, color: tc),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle.toUpperCase(),
                    style:
                        NB.label(9.5, color: tc, weight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: tc),
          ],
        ),
      ),
    );
  }
}