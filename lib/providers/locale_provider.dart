import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _languageCodeKey = 'language_code';
  static const String _countryCodeKey = 'country_code';
  
  Locale _locale = const Locale('uk', 'UA');
  
  Locale get locale => _locale;
  
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
      final languageCode = prefs.getString(_languageCodeKey) ?? 'uk';
      final countryCode = prefs.getString(_countryCodeKey) ?? 'UA';
      
      _locale = Locale(languageCode, countryCode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved language: $e');
    }
  }
  
  // Зміна мови
  Future<void> changeLanguage(Locale newLocale) async {
    if (_locale == newLocale) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, newLocale.languageCode);
      await prefs.setString(_countryCodeKey, newLocale.countryCode ?? '');
      
      _locale = newLocale;
      debugPrint('Language changed to: ${_locale.languageCode}_${_locale.countryCode}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving language: $e');
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