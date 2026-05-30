// =====================================================================
//  BRUTALIST TOGGLE  (extracted from main.dart)
//  Chunky two-state slider: hard border, hard shadow, animated accent
//  block sliding between left and right halves.  Used for UK/EN and
//  Light/Dark switches inside the Settings bottom sheet.
// =====================================================================

import 'package:flutter/material.dart';

import '../theme/neo_brutalist_theme.dart';
import 'neo_primitives.dart';

class BrutalistToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final String leftLabel;
  final String rightLabel;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final bool isLeft;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const BrutalistToggle({
    super.key,
    required this.label,
    required this.icon,
    required this.leftLabel,
    required this.rightLabel,
    required this.isLeft,
    required this.accent,
    required this.onChanged,
    this.leftIcon,
    this.rightIcon,
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
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          final fullW = constraints.maxWidth;
          final halfW = fullW / 2;
          return GestureDetector(
            onTap: () => onChanged(!isLeft),
            child: Container(
              height: 56,
              decoration: nbBlock(
                color: NB.white,
                radius: NB.radiusChunky,
                shadow: NB.hardShadow,
                borderWidth: NB.borderThick,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    left: isLeft ? 0 : halfW,
                    top: 0,
                    bottom: 0,
                    width: halfW,
                    child: Container(
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(
                              isLeft ? NB.radiusChunky - 2 : 0),
                          right: Radius.circular(
                              isLeft ? 0 : NB.radiusChunky - 2),
                        ),
                        border:
                            Border.all(color: NB.ink, width: NB.borderThick),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _toggleHalf(
                          label: leftLabel,
                          icon: leftIcon,
                          active: isLeft,
                        ),
                      ),
                      Expanded(
                        child: _toggleHalf(
                          label: rightLabel,
                          icon: rightIcon,
                          active: !isLeft,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _toggleHalf({
    required String label,
    required bool active,
    IconData? icon,
  }) {
    final activeText = (accent == NB.electricBlue ||
            accent == NB.neonPink ||
            accent == NB.hotRed)
        ? Colors.white
        : Colors.black;
    final color = active ? activeText : NB.mutedInk;
    return SizedBox(
      height: 56,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: NB.label(13, weight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}