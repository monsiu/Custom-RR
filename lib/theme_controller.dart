import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted, app-wide theme selection (System / Light / Dark) plus an
/// optional AMOLED (true-black) flag that applies on top of the dark
/// variant.
///
/// Exposed as a singleton [ValueNotifier] so widgets can rebuild via
/// [ValueListenableBuilder] without taking on a state-management dependency.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);

  static final ThemeController instance = ThemeController._();

  static const String _prefsKey = 'theme_mode';
  static const String _amoledKey = 'theme_amoled';

  /// True when the user has opted into AMOLED (pure-black) dark surfaces.
  /// Has no visual effect in light mode but is persisted independently so
  /// switching back to dark restores the preference.
  final ValueNotifier<bool> amoled = ValueNotifier<bool>(false);

  /// Load the saved theme mode from disk. Call once during app startup.
  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_prefsKey);
    value = _fromString(raw);
    amoled.value = prefs.getBool(_amoledKey) ?? false;
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == value) return;
    value = mode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _toString(mode));
  }

  Future<void> setAmoled(bool enabled) async {
    if (enabled == amoled.value) return;
    amoled.value = enabled;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_amoledKey, enabled);
  }

  static ThemeMode _fromString(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
