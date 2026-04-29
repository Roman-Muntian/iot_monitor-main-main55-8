// =====================================================================
//  NEO-BRUTALIST THEME — IoT MONITOR
//  Single source of truth for colors, typography, borders & hard shadows.
//
//  ── DARK / LIGHT MODE ────────────────────────────────────────────────
//  Colors are exposed as static *getters* that swap based on the
//  NB._dark flag (toggled via AppState).  This keeps every existing
//  call site (NB.paper, NB.ink, NB.neonYellow, ...) working unchanged.
//
//  Light theme : crisp paper background, black ink, vibrant flat accents.
//  Dark theme  : near-black paper, off-white ink, HOT MAGENTA primary
//                accent + neon green/yellow secondary accents.
//
//  Brutalist DNA preserved in BOTH modes:
//    * 2.5 px solid borders, 2.0 px thin
//    * Hard shadows (offset, NO blur)
//    * Sharp / chunky typography (Archivo Black + Space Grotesk)
//
//  ── CYRILLIC SUPPORT ────────────────────────────────────────────────
//  Archivo Black + Space Grotesk do NOT include the Cyrillic subset, so
//  Ukrainian text used to fall back to the system sans-serif (visually
//  inconsistent with English).  We now layer brutalist Cyrillic-capable
//  Google Fonts via `fontFamilyFallback`:
//    Archivo Black  ⟶ fallback Unbounded (w900)     ✓ Cyrillic chunky
//    Space Grotesk  ⟶ fallback Manrope (matched w)  ✓ Cyrillic geo-sans
//    Mono digits    ⟶ fallback JetBrains Mono       ✓ Cyrillic mono
//  English glyphs still render with the originals; Ukrainian glyphs use
//  the fallback.  Both languages now look 100% brutalist.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NB {
  NB._();

  // ── Mode flag ─────────────────────────────────────────────────────
  static bool _dark = false;
  static void setDark(bool dark) {
    _dark = dark;
  }

  static bool get isDark => _dark;

  // ── PALETTE — LIGHT (defaults / day) ──────────────────────────────
  static const Color _paperLight = Color(0xFFF4F4F4);
  static const Color _inkLight = Color(0xFF000000);
  static const Color _whiteLight = Color(0xFFFFFFFF);
  static const Color _softWhiteLight = Color(0xFFFAFAFA);
  static const Color _subtleGreyLight = Color(0xFFE5E5E5);
  static const Color _charcoalLight = Color(0xFF1A1A1A);

  static const Color _neonYellowLight = Color(0xFFFFF000);
  static const Color _electricBlueLight = Color(0xFF0055FF);
  static const Color _mintGreenLight = Color(0xFF00FF90);
  static const Color _hotRedLight = Color(0xFFFF3D2E);
  static const Color _neonPinkLight = Color(0xFFFF4FD8);
  static const Color _mutedInkLight = Color(0xFF6E6E6E);

  // ── PALETTE — DARK (Hot Magenta brutal night) ─────────────────────
  static const Color _paperDark = Color(0xFF050505);
  static const Color _inkDark = Color(0xFFEDEDED);
  static const Color _whiteDark = Color(0xFF181818);
  static const Color _softWhiteDark = Color(0xFF141414);
  static const Color _subtleGreyDark = Color(0xFF2A2A2A);
  static const Color _charcoalDark = Color(0xFF000000);

  static const Color _neonYellowDark = Color(0xFFE8FF1A);
  static const Color _electricBlueDark = Color(0xFFFF10F0); // HOT MAGENTA
  static const Color _mintGreenDark = Color(0xFF39FF14);
  static const Color _hotRedDark = Color(0xFFFF4D5E);
  static const Color _neonPinkDark = Color(0xFFFF10F0);
  static const Color _mutedInkDark = Color(0xFF9A9A9A);

  // ── PUBLIC GETTERS ────────────────────────────────────────────────
  static Color get paper => _dark ? _paperDark : _paperLight;
  static Color get ink => _dark ? _inkDark : _inkLight;
  static Color get white => _dark ? _whiteDark : _whiteLight;
  static Color get softWhite => _dark ? _softWhiteDark : _softWhiteLight;
  static Color get subtleGrey => _dark ? _subtleGreyDark : _subtleGreyLight;
  static Color get charcoal => _dark ? _charcoalDark : _charcoalLight;
  static Color get neonYellow => _dark ? _neonYellowDark : _neonYellowLight;
  static Color get electricBlue =>
      _dark ? _electricBlueDark : _electricBlueLight;
  static Color get mintGreen => _dark ? _mintGreenDark : _mintGreenLight;
  static Color get hotRed => _dark ? _hotRedDark : _hotRedLight;
  static Color get neonPink => _dark ? _neonPinkDark : _neonPinkLight;
  static Color get mutedInk => _dark ? _mutedInkDark : _mutedInkLight;

  // ── BORDERS ───────────────────────────────────────────────────────
  static const double borderThick = 2.5;
  static const double borderThin = 2.0;

  static Border outline({Color? color, double width = borderThick}) =>
      Border.all(color: color ?? ink, width: width);

  // ── HARD SHADOWS (NO BLUR) ─────────────────────────────────────────
  static List<BoxShadow> get hardShadow => [
        BoxShadow(
            color: ink, offset: const Offset(5, 5), blurRadius: 0, spreadRadius: 0),
      ];

  static List<BoxShadow> get hardShadowSm => [
        BoxShadow(
            color: ink, offset: const Offset(3, 3), blurRadius: 0, spreadRadius: 0),
      ];

  static List<BoxShadow> get hardShadowLg => [
        BoxShadow(
            color: ink, offset: const Offset(7, 7), blurRadius: 0, spreadRadius: 0),
      ];

  static const List<BoxShadow> hardShadowNone = [];

  // ── RADII ─────────────────────────────────────────────────────────
  static const double radiusSharp = 0;
  static const double radiusChunky = 12;

  // ── TYPOGRAPHY HELPERS ────────────────────────────────────────────
  // Resolved fallback family names (cached after first lookup).  The
  // GoogleFonts call ALSO triggers the underlying font asset to load,
  // so by the time a Cyrillic glyph needs to be drawn the fallback is
  // ready.
  static List<String> _fallbackChain(_FbKind kind, FontWeight w) {
    final chain = <String>[];
    switch (kind) {
      case _FbKind.display:
        chain.add(GoogleFonts.unbounded(fontWeight: FontWeight.w900).fontFamily!);
        chain.add(GoogleFonts.manrope(fontWeight: FontWeight.w900).fontFamily!);
        break;
      case _FbKind.sans:
        chain.add(GoogleFonts.manrope(fontWeight: w).fontFamily!);
        chain.add(GoogleFonts.unbounded(fontWeight: w).fontFamily!);
        break;
      case _FbKind.mono:
        chain.add(GoogleFonts.jetBrainsMono(fontWeight: w).fontFamily!);
        chain.add(GoogleFonts.manrope(fontWeight: w).fontFamily!);
        break;
    }
    return chain;
  }

  // ── TYPOGRAPHY ────────────────────────────────────────────────────
  /// Display / headings — heavy black sans-serif (Cyrillic ⟶ Unbounded 900).
  static TextStyle display(double size, {Color? color}) =>
      GoogleFonts.archivoBlack(
        textStyle: TextStyle(
          fontSize: size,
          color: color ?? ink,
          height: 1.0,
          letterSpacing: 0.5,
          fontFamilyFallback:
              _fallbackChain(_FbKind.display, FontWeight.w900),
        ),
      );

  /// Loud body / numbers — Space Grotesk; Cyrillic ⟶ JetBrains Mono.
  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) =>
      GoogleFonts.spaceGrotesk(
        textStyle: TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color ?? ink,
          height: 1.0,
          letterSpacing: -0.5,
          fontFamilyFallback: _fallbackChain(_FbKind.mono, weight),
        ),
      );

  /// Body labels — bold sans-serif with tracking; Cyrillic ⟶ Manrope.
  static TextStyle label(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color? color,
  }) =>
      GoogleFonts.spaceGrotesk(
        textStyle: TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color ?? ink,
          height: 1.2,
          letterSpacing: 1.5,
          fontFamilyFallback: _fallbackChain(_FbKind.sans, weight),
        ),
      );

  /// Body text — readable copy; Cyrillic ⟶ Manrope.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) =>
      GoogleFonts.spaceGrotesk(
        textStyle: TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color ?? ink,
          height: 1.4,
          letterSpacing: 0.2,
          fontFamilyFallback: _fallbackChain(_FbKind.sans, weight),
        ),
      );
}

enum _FbKind { display, sans, mono }

// ── BLOCK DECORATION HELPER ─────────────────────────────────────────
BoxDecoration nbBlock({
  Color? color,
  Color? borderColor,
  double radius = NB.radiusChunky,
  List<BoxShadow>? shadow,
  double borderWidth = NB.borderThick,
}) {
  return BoxDecoration(
    color: color ?? NB.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? NB.ink, width: borderWidth),
    boxShadow: shadow ?? NB.hardShadow,
  );
}
