import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Вибір оформлення: як у телефоні, світле або темне.
///
/// За замовчуванням — системне: користувач, який тримає телефон у темному
/// режимі, очікує темний застосунок і не має шукати для цього перемикач.
class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = _decode(prefs.getString(_key));
      notifyListeners();
    } catch (_) {
      // Залишаємось на системному — це безпечний стандарт.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _encode(mode));
    } catch (_) {}
  }

  static ThemeMode _decode(String? v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _encode(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
