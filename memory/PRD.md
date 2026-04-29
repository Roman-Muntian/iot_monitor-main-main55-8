# IoT Monitor — Localization, Themes, Typography & Modular Refactor

## Original Problem Statement
Add to an existing Flutter "IoT Monitor" app, built with a strict Neo-Brutalist
design system, the following without breaking any existing business logic,
layout, or aesthetic:

1. **Localization (Ukrainian default + English toggle)** for all hardcoded
   strings in `main.dart`, `analytics_screen.dart`, `log_screen.dart`, etc.,
   persisted via `shared_preferences`.
2. **Light / Dark theme toggle** — Dark mode follows brutalist rules
   (2.5 px borders, hard shadows offset 5,5 blur 0, chunky typography) but
   uses near-black backgrounds, contrasting borders, and **HOT MAGENTA**
   neon accents. Persisted via `shared_preferences`.
3. **Typography consistency** — Ukrainian text must render in the same
   chunky brutalist Google Fonts as English (the originals — Archivo Black
   and Space Grotesk — do NOT support Cyrillic and were silently falling
   back to system sans-serif).
4. **Modular refactor** — extract heavy UI chunks from `main.dart` into
   their own widget files under `lib/widgets/` without changing the
   rendered UI in any way.

State management: minimal native — `ChangeNotifier` wrapped at the root
(no Bloc / Riverpod / GetX).

Strict constraints:
- Zero layout breakage (no padding/flex/hierarchy changes).
- `mqtt_service.dart`, `db_service.dart`, `export_service.dart`,
  simulator and `notification_service.dart` MUST remain untouched.

## User Choices Confirmed
- Codebase: provided in `/app` (Flutter project).
- Dark mode accent: **Hot Magenta (#FF10F0)**.
- Settings UI: **Brutalist toggle switch** (chunky two-state slider).
- Translation fallback: **Ukrainian**.
- No external API/LLM integration needed (pure static dictionary).

## Architecture (Final)
### Localization
- `lib/i18n/app_strings.dart` — Static `Map<String, Map<String, String>>`
  with `uk` and `en` keys + `S.tr(key, langCode)` helper (UK fallback).

### State management
- `lib/app_state.dart` — `AppState extends ChangeNotifier` singleton with
  `langCode` and `isDark` getters; `load()`, `setLang()`, `setDark()`,
  `toggleDark()`, `toggleLang()`. Persists to SharedPreferences. Top-level
  `t(key)` helper resolves to active locale. NB.setDark is synced inside
  AppState.setDark/load.

### Theme
- `lib/theme/neo_brutalist_theme.dart` — `NB` class palette is exposed as
  static **getters** that swap based on internal `_dark` flag. Public API
  (`NB.paper`, `NB.ink`, `NB.neonYellow`, ...) unchanged.
  - Light: original (paper #F4F4F4, ink #000, neon yellow/blue/mint).
  - Dark: paper #050505, ink #EDEDED, electricBlue → **#FF10F0 Hot Magenta**,
    mint → #39FF14, yellow → #E8FF1A, hot red softened.
  - Hard shadows use the active `ink` color (white shadows on dark paper).
  - Borders 2.5/2.0 px, radii 0/12 unchanged.

### Typography (Cyrillic support)
- Primary fonts kept (Archivo Black + Space Grotesk) for English/Latin.
- `fontFamilyFallback` chains added inside `NB.display/mono/label/body`:
    - **Unbounded** w900 → brutalist chunky Cyrillic-capable display fallback.
    - **Manrope** (matched weight) → geometric Cyrillic-capable body fallback.
    - **JetBrains Mono** (matched weight) → monospace Cyrillic fallback for
      sensor digit readouts.
  Effect: English glyphs continue to render in the originals (zero visual
  change), while Ukrainian glyphs render in chunky brutalist Cyrillic fonts
  instead of system default. Both languages now look 100% brutalist.

### Modular widgets (extracted from main.dart)
- `lib/widgets/brutalist_app_bar.dart` — `BrutalistAppBar` + connection status.
- `lib/widgets/hero_block.dart` — `HeroBlock`.
- `lib/widgets/sensor_card.dart` — `SensorCard` (animated value, alarm swap).
- `lib/widgets/last_update_block.dart` — `LastUpdateBlock`.
- `lib/widgets/dashboard_drawer.dart` — `DashboardDrawer` + `_DrawerItem`.
- `lib/widgets/alarm_overlay.dart` — `AlarmOverlay` + `_AlarmBanner`
  + `_localizeAlarm` helper.
- `lib/widgets/settings_sheet.dart` — `showSettingsSheet(context, mqtt)`
  top-level function + `_SettingsSheetContent` stateful widget.
- `lib/widgets/brutalist_range_slider.dart` — `BrutalistRangeSlider`.
- `lib/widgets/brutalist_toggle.dart` — `BrutalistToggle`.
- `lib/widgets/neo_widgets.dart` — Pre-existing reusable primitives
  (NeoCard, NeoButton, NeoTag, NeoIconBox, NeoSectionHeader, NeoStripeBackground).

### main.dart
- Down from 1123 → ~183 lines.
- Just `MyApp` (MaterialApp inside AnimatedBuilder bound to AppState),
  `Dashboard` (state holds `mqtt`, `_dbService`, `_lastUpdate`,
  `_exportData`), and a clean composition of the extracted widgets.

## Files Modified
- `lib/main.dart` — slim composition layer.
- `lib/log_screen.dart` — translations, filter values preserved.
- `lib/analytics_screen.dart` — translations.
- `lib/theme/neo_brutalist_theme.dart` — palette getters + Cyrillic fallback chains.
- `lib/widgets/neo_widgets.dart` — null defaults so dark-mode swap works.

## Files Created
- `lib/i18n/app_strings.dart`
- `lib/app_state.dart`
- `lib/widgets/alarm_overlay.dart`
- `lib/widgets/brutalist_app_bar.dart`
- `lib/widgets/brutalist_range_slider.dart`
- `lib/widgets/brutalist_toggle.dart`
- `lib/widgets/dashboard_drawer.dart`
- `lib/widgets/hero_block.dart`
- `lib/widgets/last_update_block.dart`
- `lib/widgets/sensor_card.dart`
- `lib/widgets/settings_sheet.dart`

## Files Untouched (per PRD constraints)
- `lib/mqtt_service.dart`
- `lib/db_service.dart`
- `lib/export_service.dart`
- `lib/notification_service.dart`
- `lib/settings_service.dart`
- `lib/mqtt_setup_io.dart`, `lib/mqtt_setup_web.dart`, `lib/mqtt_setup.dart`
- `pubspec.yaml` (no new dependencies — `google_fonts`, `shared_preferences`
  already present; Unbounded / Manrope / JetBrains Mono are loaded via the
  existing `google_fonts` runtime mechanism).

## Implementation Date
Jan 2026

## Validation
- ARM64 container; Flutter SDK has no official Linux ARM build, so
  `flutter analyze` was not run in the dev container.
- Static review: zero `const` constructors reference NB getters, all
  imports correct, all old private methods (`_buildSensorCard`, `_buildDrawer`,
  `_showSettings`, `_BrutalistRangeSlider`, `_BrutalistToggle`, etc.) removed
  and replaced by their public widget equivalents.
- main.dart shrank from 1123 → 183 lines.
- **User must run `flutter pub get && flutter run` on their dev machine
  to confirm runtime behavior.**

## Backlog / Future Enhancements
- Add `flutter_localizations` if the user later wants the Material
  DatePicker to display Ukrainian month names natively.
- Honor system-level `MediaQuery.platformBrightness` as a 3rd "Auto"
  theme option.
- Animate the palette swap with `AnimatedTheme` for a smoother transition.

## Smart Enhancement Suggestion
**Push-to-share telemetry snapshots**: add a one-tap "Share" button
next to "Download CSV" that exports the last 24 h of readings as a
brutalist-branded PNG chart for instant Telegram / Twitter sharing.
Uses `share_plus` already in `pubspec.yaml`. Tiny code surface,
high virality — every shared image is free organic marketing.
