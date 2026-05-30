import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../analytics_screen.dart';
import '../app_state.dart';
import '../log_screen.dart';
import '../mqtt_service.dart';
import '../theme/neo_brutalist_theme.dart';
import 'neo_primitives.dart';

class DashboardDrawer extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onExport;
  final MqttService mqtt;
  // ← ОПТИМІЗАЦІЯ: отримуємо стан як параметр, StreamBuilder прибрано
  final MqttConnectionState connectionState;

  const DashboardDrawer({
    super.key,
    required this.onOpenSettings,
    required this.onExport,
    required this.mqtt,
    required this.connectionState,
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
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    t('main_menu'),
                    style: NB.label(11, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),

                  _DrawerItem(
                    title: t('limits_settings'),
                    icon: LucideIcons.slidersHorizontal,
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
                    icon: LucideIcons.clipboardList,
                    color: NB.electricBlue,
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LogScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  _DrawerItem(
                    title: t('analytics'),
                    icon: LucideIcons.chartBar,
                    color: NB.mintGreen,
                    textColor: Colors.black,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 22),
                  Container(height: 2.5, color: NB.ink),
                  const SizedBox(height: 22),

                  Text(
                    t('export_section'),
                    style: NB.label(11, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  _DrawerItem(
                    title: t('download_csv'),
                    subtitle: t('download_csv_sub'),
                    icon: LucideIcons.cloudDownload,
                    color: NB.white,
                    onTap: () {
                      Navigator.pop(context);
                      onExport();
                    },
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: NB.white,
                border: Border(
                  top: BorderSide(color: NB.ink, width: NB.borderThick),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.zap, size: 16, color: NB.ink),
                  const SizedBox(width: 8),
                  Text(
                    'KlimaBox',
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

  Widget _buildHeader() {
    // ← визначаємо тег без StreamBuilder
    final NeoTag statusTag;
    if (connectionState == MqttConnectionState.connected) {
      statusTag = NeoTag.success(t('connected'), icon: LucideIcons.signal);
    } else if (connectionState == MqttConnectionState.connecting) {
      statusTag = NeoTag.warn(t('connecting'), icon: LucideIcons.loader);
    } else {
      statusTag = NeoTag.error(t('disconnected'), icon: LucideIcons.wifiOff);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: NB.electricBlue,
        border: Border(
          bottom: BorderSide(color: NB.ink, width: NB.borderThick),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: NB.borderThick),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            child: Text(
              t('user_name'),
              style: NB.display(16, color: Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              NeoTag(
                label: t('user_group'),
                color: NB.neonYellow,
                textColor: Colors.black,
              ),
              const SizedBox(width: 8),
              statusTag,
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Color? textColor;

  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: NB.body(14, weight: FontWeight.w800, color: tc),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!.toUpperCase(),
                      style: NB.label(9.5, color: tc, weight: FontWeight.w800),
                    ),
                  ],
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