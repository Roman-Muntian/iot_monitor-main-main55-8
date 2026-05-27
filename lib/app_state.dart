// =====================================================================
//  APP STATE — minimal native ChangeNotifier holding language + theme
//  Persists user preferences via shared_preferences.
//  Default language: Ukrainian.  Default theme: Light.
//  Wrap the root MaterialApp with AnimatedBuilder/ListenableBuilder
//  so the whole tree rebuilds when the user toggles language or theme.
// =====================================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i18n/app_strings.dart';
import 'theme/neo_brutalist_theme.dart';

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  // Persistence keys
  static const String _kLang = 'app_lang';
  static const String _kTheme = 'app_theme_dark';

  String _langCode = 'uk';
  bool _isDark = false;

  String get langCode => _langCode;
  bool get isDark => _isDark;

  /// Load saved preferences from disk.  Called once before runApp().
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _langCode = prefs.getString(_kLang) ?? 'uk';
    _isDark = prefs.getBool(_kTheme) ?? false;
    NB.setDark(_isDark);
    notifyListeners();
  }

  Future<void> setLang(String code) async {
    if (_langCode == code) return;
    _langCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, code);
  }

  Future<void> setDark(bool dark) async {
    if (_isDark == dark) return;
    _isDark = dark;
    NB.setDark(dark);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTheme, dark);
  }

  Future<void> toggleDark() => setDark(!_isDark);
  Future<void> toggleLang() =>
      setLang(_langCode == 'uk' ? 'en' : 'uk');
}

/// Top-level translation helper.  Reads the current AppState language.
/// Because the widget tree is rebuilt under an AnimatedBuilder bound to
/// AppState, this function naturally resolves to the active locale.
String t(String key) => S.tr(key, AppState.instance.langCode);