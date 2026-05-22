// =====================================================================
//  SETTINGS BOTTOM SHEET — МИТТЄВЕ ПЕРЕМИКАННЯ (БЕЗ ЗАТРИМОК)
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app_state.dart';
import '../mqtt_service.dart';
import '../theme/neo_brutalist_theme.dart';
import 'brutalist_range_slider.dart';
import 'brutalist_toggle.dart';
import 'neo_widgets.dart';

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
    // ListenableBuilder автоматично оновлює меню миттєво при зміні мови чи теми
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
              // Title + reset
              Row(
                children: [
                  // Обертаємо текст у Expanded, щоб він міг стискатися,
                  // а не виштовхувати кнопку за межі екрана
                  Expanded(
                    child: Text(
                      t('settings_title'), 
                      style: NB.display(18),
                      maxLines: 1, // Не дозволяємо переноситись на новий рядок
                      overflow: TextOverflow.ellipsis, // Додаємо три крапки, якщо не влазить
                    ),
                  ),
                  const SizedBox(width: 8), // Невеликий відступ між текстом і кнопкою
                  NeoButton(
                    color: NB.neonYellow,
                    textColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        mqtt.settings.update(18, 26, 40, 60);
                        mqtt.settings.tempMin = 18;
                        mqtt.settings.tempMax = 26;
                        mqtt.settings.humMin = 40;
                        mqtt.settings.humMax = 60;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.refreshCcw, size: 14),
                        const SizedBox(width: 6),
                        Text(t('reset')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Range sliders
              BrutalistRangeSlider(
                label: t('temperature'),
                unit: "°C",
                icon: LucideIcons.thermometer,
                accent: NB.neonYellow,
                accentTextColor: Colors.black,
                min: mqtt.settings.tempMin,
                max: mqtt.settings.tempMax,
                onChanged: (v) => setState(() {
                  mqtt.settings.tempMin = v.start;
                  mqtt.settings.tempMax = v.end;
                }),
                onEnd: (v) => mqtt.settings.update(
                  v.start,
                  v.end,
                  mqtt.settings.humMin,
                  mqtt.settings.humMax,
                ),
              ),
              const SizedBox(height: 22),
              BrutalistRangeSlider(
                label: t('humidity'),
                unit: "%",
                icon: LucideIcons.droplets,
                accent: NB.electricBlue,
                accentTextColor: Colors.white,
                min: mqtt.settings.humMin,
                max: mqtt.settings.humMax,
                onChanged: (v) => setState(() {
                  mqtt.settings.humMin = v.start;
                  mqtt.settings.humMax = v.end;
                }),
                onEnd: (v) => mqtt.settings.update(
                  mqtt.settings.tempMin,
                  mqtt.settings.tempMax,
                  v.start,
                  v.end,
                ),
              ),
              const SizedBox(height: 26),
              Container(height: 2.5, color: NB.ink),
              const SizedBox(height: 18),
              
              // Language toggle (Прибрано await для миттєвого відгуку)
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
              
              // Theme toggle (Прибрано await для миттєвого відгуку)
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