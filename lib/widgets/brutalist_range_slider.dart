// =====================================================================
//  BRUTALIST RANGE SLIDER  (extracted from main.dart)
//  Same RangeSlider with brutalist styling — visuals untouched.
//
//  FIXED: Added sliderMin and sliderMax to allow negative boundaries
//  and dynamic divisions.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/neo_brutalist_theme.dart';
import 'neo_widgets.dart';

class BrutalistRangeSlider extends StatelessWidget {
  final String label, unit;
  final IconData icon;
  final Color accent;
  final Color accentTextColor;
  
  // Поточні вибрані межі
  final double min, max; 
  
  // Абсолютні межі самого повзунка (від і до яких він рухається)
  final double sliderMin, sliderMax; 
  
  final ValueChanged<RangeValues> onChanged;
  final ValueChanged<RangeValues> onEnd;

  const BrutalistRangeSlider({
    super.key,
    required this.label,
    required this.unit,
    required this.icon,
    required this.accent,
    required this.min,
    required this.max,
    this.sliderMin = 0.0,    // Значення за замовчуванням, щоб не зламати старий код
    this.sliderMax = 100.0,  // Значення за замовчуванням
    required this.onChanged,
    required this.onEnd,
    this.accentTextColor = const Color(0xFF000000),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            NeoIconBox(
                icon: icon, background: accent, size: 38, iconSize: 18),
            const SizedBox(width: 10),
            Text(label, style: NB.display(14)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: nbBlock(
                color: accent,
                radius: 4,
                shadow: NB.hardShadowSm,
                borderWidth: NB.borderThin,
              ),
              child: Text(
                "${min.round()}–${max.round()} $unit",
                style: NB.label(11,
                    color: accentTextColor, weight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: NB.ink,
            inactiveTrackColor: NB.subtleGrey,
            thumbColor: accent,
            overlayColor: NB.ink.withValues(alpha: 0.05),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 0,
              pressedElevation: 0,
            ),
            rangeTickMarkShape: const RoundRangeSliderTickMarkShape(),
          ),
          child: RangeSlider(
            values: RangeValues(min, max),
            // ВИПРАВЛЕНО: Тепер використовуємо абсолютні межі
            min: sliderMin,
            max: sliderMax,
            // ВИПРАВЛЕНО: Кількість кроків рахується динамічно
            divisions: (sliderMax - sliderMin).toInt(), 
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            onChangeEnd: onEnd,
          ),
        ),
      ],
    );
  }
}