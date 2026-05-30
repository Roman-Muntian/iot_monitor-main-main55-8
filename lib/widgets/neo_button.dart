import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/neo_brutalist_theme.dart';

class NeoButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final EdgeInsets padding;
  final double radius;
  final bool fullWidth;

  const NeoButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.radius = NB.radiusChunky,
    this.fullWidth = false,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final bgColor = isDisabled ? NB.subtleGrey : (widget.color ?? NB.neonYellow);
    final txtColor = isDisabled ? NB.mutedInk : (widget.textColor ?? NB.ink);

    final btn = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      transform: _pressed
          ? Matrix4.translationValues(5.0, 5.0, 0.0)
          : Matrix4.identity(),
      padding: widget.padding,
      decoration: nbBlock(
        color: bgColor,
        radius: widget.radius,
        shadow: _pressed ? NB.hardShadowNone : NB.hardShadow,
      ),
      child: DefaultTextStyle.merge(
        style: NB.label(14, color: txtColor),
        child: IconTheme(
          data: IconThemeData(color: txtColor, size: 20),
          child: widget.child,
        ),
      ),
    );

    if (isDisabled) {
      return widget.fullWidth
          ? SizedBox(width: double.infinity, child: btn)
          : btn;
    }

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.selectionClick();
      },
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      child: widget.fullWidth
          ? SizedBox(width: double.infinity, child: btn)
          : btn,
    );
  }
}