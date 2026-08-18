import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/error_reporter.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _languageCodeKey = 'language_code';
  static const String _countryCodeKey = 'country_code';
  static const String _followSystemKey = 'language_follow_system';
  
  /// `null` означає «як у налаштуваннях телефона»: MaterialApp сам обере
  /// найближчу з підтримуваних мов, а якщо системної немає — першу зі списку.
  Locale? _locale;
  bool _followSystem = true;

  /// Те, що віддається в MaterialApp. `null` — слідувати за системою.
  Locale? get locale => _followSystem ? null : _locale;

  /// Мова, якою застосунок показується фактично. Потрібна там, де треба
  /// зберегти вибір на сервер або підсвітити активний пункт у налаштуваннях.
  Locale get effectiveLocale =>
      _followSystem ? _resolveSystemLocale() : (_locale ?? const Locale('uk', 'UA'));

  bool get followSystem => _followSystem;

  /// Системна мова, зведена до підтримуваної. Якщо телефон, наприклад,
  /// німецькою — беремо англійську, а не показуємо порожнечу.
  static Locale _resolveSystemLocale() {
    final system = PlatformDispatcher.instance.locale;
    for (final l in supportedLocales) {
      if (l.languageCode == system.languageCode) return l;
    }
    return const Locale('en', 'US');
  }
  
  // Доступні мови
  static const List<Locale> supportedLocales = [
    Locale('uk', 'UA'), // 🇺🇦 Українська
    Locale('pl', 'PL'), // 🇵🇱 Польська
    Locale('pt', 'PT'), // 🇵🇹 Португальська
    Locale('es', 'ES'), // 🇪🇸 Іспанська
    Locale('en', 'US'), // 🇬🇧 Англійська
  ];
  
  // Назви мов
  static const Map<String, String> languageNames = {
    'uk': '🇺🇦 Українська',
    'pl': '🇵🇱 Polski',
    'pt': '🇵🇹 Português',
    'es': '🇪🇸 Español',
    'en': '🇬🇧 English',
  };
  
  LocaleProvider() {
    _loadSavedLanguage();
  }
  
  // Завантаження збереженої мови
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Для нових користувачів за замовчуванням — мова телефона.
      _followSystem = prefs.getBool(_followSystemKey) ??
          !prefs.containsKey(_languageCodeKey);

      final languageCode = prefs.getString(_languageCodeKey) ?? 'uk';
      final countryCode = prefs.getString(_countryCodeKey) ?? 'UA';
      _locale = Locale(languageCode, countryCode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved language: $e');
    }
  }
  
  // Зміна мови
  /// Повернутись до мови телефона.
  Future<void> useSystemLanguage() async {
    _followSystem = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_followSystemKey, true);
    notifyListeners();
    await syncLocaleToProfile();
  }

  Future<void> changeLanguage(Locale newLocale) async {
    if (!_followSystem && _locale == newLocale) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, newLocale.languageCode);
      await prefs.setString(_countryCodeKey, newLocale.countryCode ?? '');
      await prefs.setBool(_followSystemKey, false);

      _followSystem = false;
      _locale = newLocale;
      debugPrint('Language changed to: ${newLocale.languageCode}_${newLocale.countryCode}');
      notifyListeners();

      await syncLocaleToProfile();
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  /// Мова зберігається і в профілі, бо тексти пушів добирає сервер: він єдиний,
  /// хто знає, якою мовою читає отримувач.
  Future<void> syncLocaleToProfile() async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;
    try {
      await client.rpc('set_my_locale',
          params: {'p_locale': effectiveLocale.languageCode});
    } catch (e, st) {
      // Не критично: сервер має запасне значення 'uk'.
      ErrorReporter.report(e, st, context: 'syncLocaleToProfile');
    }
  }
  
  // Зміна мови за кодом
  Future<void> changeLanguageByCode(String languageCode) async {
    debugPrint('Changing language to: $languageCode');
    final newLocale = supportedLocales.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => const Locale('uk', 'UA'),
    );
    
    debugPrint('New locale: ${newLocale.languageCode}_${newLocale.countryCode}');
    await changeLanguage(newLocale);
  }
  
  /// Мови у порядку показу в налаштуваннях.
  static const List<String> languageCodes = ['uk', 'en', 'pl', 'es', 'pt'];

  // Отримання назви мови
  static String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }
  
  // Отримання коду мови
  static String getLanguageCode(String languageName) {
    final entry = languageNames.entries.firstWhere(
      (entry) => entry.value == languageName,
      orElse: () => const MapEntry('uk', '🇺🇦 Українська'),
    );
    return entry.key;
  }
  
  // Доступні мови для UI
  static List<String> get availableLanguages => languageNames.values.toList();
} 