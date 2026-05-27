// =====================================================================
//  NEO-BRUTALIST WIDGETS — Reusable building blocks
//  - NeoCard          : container w/ thick border + hard shadow
//  - NeoButton        : pressable block button (shadow shifts on press)
//  - NeoTag           : status tag (ERROR / INFO / WARN ...)
//  - NeoIconBox       : icon wrapped in a colored bordered square
//  - NeoSectionHeader : printed-look section title
//
//  NOTE: defaults that previously referenced `NB.<color>` constants
//  (now palette-aware getters) are nullable and resolved inside build()
//  so light/dark theme swap takes effect without touching call sites.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/neo_brutalist_theme.dart';

// ─────────────────────────────────────────────────────────────────────
// NeoCard
// ─────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────
// NeoButton — pressable block (shadow disappears on press)
// ─────────────────────────────────────────────────────────────────────
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
    final txtColor = widget.textColor ?? NB.ink;
    final btn = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      transform: _pressed
          ? Matrix4.translationValues(5.0, 5.0, 0.0)
          : Matrix4.identity(),
      padding: widget.padding,
      decoration: nbBlock(
        color: widget.color ?? NB.neonYellow,
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

// ─────────────────────────────────────────────────────────────────────
// NeoTag — high-contrast status indicator
// Variants are encoded as an internal enum so factories don't need to
// invoke (non-const) NB getters from a const-allowed context.
// ─────────────────────────────────────────────────────────────────────
enum _NeoTagVariant { custom, error, info, success, warn }

class NeoTag extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final double fontSize;
  final IconData? icon;
  final _NeoTagVariant _variant;

  const NeoTag({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.fontSize = 11,
    this.icon,
  }) : _variant = _NeoTagVariant.custom;

  const NeoTag._variant({
    super.key,
    required this.label,
    required _NeoTagVariant variant,
    this.fontSize = 11,
    this.icon,
  })  : color = null,
        textColor = null,
        _variant = variant;

  /// Bright RED block — used for errors / anomalies
  factory NeoTag.error(String label,
          {Key? key, IconData? icon, double fontSize = 11}) =>
      NeoTag._variant(
          key: key,
          label: label,
          variant: _NeoTagVariant.error,
          icon: icon,
          fontSize: fontSize);

  /// Electric BLUE — info entries
  factory NeoTag.info(String label,
          {Key? key, IconData? icon, double fontSize = 11}) =>
      NeoTag._variant(
          key: key,
          label: label,
          variant: _NeoTagVariant.info,
          icon: icon,
          fontSize: fontSize);

  /// Mint / Neon GREEN — success / healthy
  factory NeoTag.success(String label,
          {Key? key, IconData? icon, double fontSize = 11}) =>
      NeoTag._variant(
          key: key,
          label: label,
          variant: _NeoTagVariant.success,
          icon: icon,
          fontSize: fontSize);

  /// Neon YELLOW — warning
  factory NeoTag.warn(String label,
          {Key? key, IconData? icon, double fontSize = 11}) =>
      NeoTag._variant(
          key: key,
          label: label,
          variant: _NeoTagVariant.warn,
          icon: icon,
          fontSize: fontSize);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (_variant) {
      case _NeoTagVariant.error:
        bg = NB.hotRed;
        fg = Colors.white;
        break;
      case _NeoTagVariant.info:
        bg = NB.electricBlue;
        fg = Colors.white;
        break;
      case _NeoTagVariant.success:
        bg = NB.mintGreen;
        fg = Colors.black;
        break;
      case _NeoTagVariant.warn:
        bg = NB.neonYellow;
        fg = Colors.black;
        break;
      case _NeoTagVariant.custom:
        bg = color ?? NB.neonYellow;
        fg = textColor ?? NB.ink;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: nbBlock(
        color: bg,
        radius: 4,
        shadow: NB.hardShadowSm,
        borderWidth: NB.borderThin,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: NB.label(fontSize, color: fg, weight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// NeoIconBox — thick-stroke icon wrapped in a colored bordered square
// ─────────────────────────────────────────────────────────────────────
class NeoIconBox extends StatelessWidget {
  final IconData icon;
  final Color? background;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const NeoIconBox({
    super.key,
    required this.icon,
    this.background,
    this.iconColor,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: nbBlock(
        color: background ?? NB.neonYellow,
        radius: 6,
        shadow: NB.hardShadowSm,
        borderWidth: NB.borderThin,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: iconColor ?? NB.ink),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// NeoSectionHeader — bold, uppercase, with a thick rule below
// ─────────────────────────────────────────────────────────────────────
class NeoSectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const NeoSectionHeader({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(), style: NB.display(13)),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 6),
        Container(height: 2.5, color: NB.ink),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// NeoStripeBackground — diagonal hazard stripes used in alarm banners
// ─────────────────────────────────────────────────────────────────────
class NeoStripeBackground extends StatelessWidget {
  final Widget child;
  final Color? stripeA;
  final Color? stripeB;

  const NeoStripeBackground({
    super.key,
    required this.child,
    this.stripeA,
    this.stripeB,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StripePainter(
        a: stripeA ?? NB.neonYellow,
        b: stripeB ?? NB.ink,
      ),
      child: child,
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color a;
  final Color b;
  _StripePainter({required this.a, required this.b});

  @override
  void paint(Canvas canvas, Size size) {
    final paintA = Paint()..color = a;
    canvas.drawRect(Offset.zero & size, paintA);

    final paintB = Paint()..color = b;
    const stripeWidth = 14.0;
    const gap = 28.0;
    for (double x = -size.height; x < size.width; x += gap) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + stripeWidth, 0)
        ..lineTo(x + stripeWidth + size.height, size.height)
        ..lineTo(x + size.height, size.height)
        ..close();
      canvas.drawPath(path, paintB);
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter oldDelegate) =>
      oldDelegate.a != a || oldDelegate.b != b;
}