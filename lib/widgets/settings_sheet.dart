// =====================================================================
//  SETTINGS BOTTOM SHEET — МИТТЄВЕ ПЕРЕМИКАННЯ (БЕЗ ЗАТРИМОК)
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app_state.dart';
import '../mqtt_service.dart';
import '../theme/neo_brutalist_theme.dart';
import 'range_slider.dart';
import 'toggle.dart';
import 'neo_primitives.dart';

/// Show the brutalist Settings bottom sheet.
void showSettingsSheet(BuildContext context, MqttService mqtt) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SettingsSheetContent(mqtt: mqtt),
  );
}

class _SettingsSheetContent extends StatefulWidget {
  final MqttService mqtt;
  const _SettingsSheetContent({required this.mqtt});

  @override
  State<_SettingsSheetContent> createState() => _SettingsSheetContentState();
}

class _SettingsSheetContentState extends State<_SettingsSheetContent> {
  MqttService get mqtt => widget.mqtt;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
            left: 18,
            right: 18,
            top: 14,
          ),
          decoration: nbBlock(
            color: NB.white,
            radius: NB.radiusChunky,
            shadow: NB.hardShadowLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 56,
                  height: 5,
                  decoration: nbBlock(
                    color: NB.ink,
                    radius: 2,
                    shadow: NB.hardShadowNone,
                    borderWidth: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title + reset
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t('settings_title'),
                      style: NB.display(18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  NeoButton(
                    color: NB.neonYellow,
                    textColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await mqtt.settings.update(10, 30, 30, 70);
                      if (mounted) setState(() {});
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.refreshCcw, size: 14),
                        const SizedBox(width: 6),
                        Text(t('reset')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Температура — з від'ємними межами
              BrutalistRangeSlider(
                label: t('temperature'),
                unit: "°C",
                icon: LucideIcons.thermometer,
                accent: NB.neonYellow,
                accentTextColor: Colors.black,
                min: mqtt.settings.tempMin,
                max: mqtt.settings.tempMax,
                sliderMin: -20.0,
                sliderMax: 100.0,
                onChanged: (v) => setState(() {
                  mqtt.settings.tempMin = v.start;
                  mqtt.settings.tempMax = v.end;
                }),
                onEnd: (v) async {
                  await mqtt.settings.update(
                    v.start,
                    v.end,
                    mqtt.settings.humMin,
                    mqtt.settings.humMax,
                  );
                },
              ),
              const SizedBox(height: 22),

              // Вологість
              BrutalistRangeSlider(
                label: t('humidity'),
                unit: "%",
                icon: LucideIcons.droplets,
                accent: NB.electricBlue,
                accentTextColor: Colors.white,
                min: mqtt.settings.humMin,
                max: mqtt.settings.humMax,
                sliderMin: 0.0,
                sliderMax: 100.0,
                onChanged: (v) => setState(() {
                  mqtt.settings.humMin = v.start;
                  mqtt.settings.humMax = v.end;
                }),
                onEnd: (v) async {
                  await mqtt.settings.update(
                    mqtt.settings.tempMin,
                    mqtt.settings.tempMax,
                    v.start,
                    v.end,
                  );
                },
              ),
              const SizedBox(height: 26),
              Container(height: 2.5, color: NB.ink),
              const SizedBox(height: 18),

              // Мова
              BrutalistToggle(
                label: t('language'),
                icon: LucideIcons.languages,
                leftLabel: 'UK',
                rightLabel: 'EN',
                isLeft: AppState.instance.langCode == 'uk',
                accent: NB.neonYellow,
                onChanged: (left) {
                  HapticFeedback.mediumImpact();
                  AppState.instance.setLang(left ? 'uk' : 'en');
                },
              ),
              const SizedBox(height: 18),

              // Тема
              BrutalistToggle(
                label: t('theme'),
                icon: LucideIcons.contrast,
                leftLabel: t('light'),
                leftIcon: LucideIcons.sun,
                rightLabel: t('dark'),
                rightIcon: LucideIcons.moon,
                isLeft: !AppState.instance.isDark,
                accent: NB.neonPink,
                onChanged: (left) {
                  HapticFeedback.mediumImpact();
                  AppState.instance.setDark(!left);
                },
              ),
              const SizedBox(height: 18),
            ],
          ),
        );
      },
    );
  }
}