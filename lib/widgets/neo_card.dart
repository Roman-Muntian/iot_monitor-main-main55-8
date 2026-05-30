import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/neo_brutalist_theme.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final double radius;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;

  const NeoCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
    this.radius = NB.radiusChunky,
    this.shadow,
    this.onTap,
    this.borderColor,
    this.borderWidth = NB.borderThick,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      decoration: nbBlock(
        color: color ?? NB.white,
        borderColor: borderColor ?? NB.ink,
        radius: radius,
        shadow: shadow ?? NB.hardShadow,
        borderWidth: borderWidth,
      ),
      child: child,
    );
    if (onTap == null) return container;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap!();
      },
      child: container,
    );
  }
}