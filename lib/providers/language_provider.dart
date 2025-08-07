import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('uk');
  
  Locale get currentLocale => _currentLocale;
  
  static final Map<String, String> _languageNames = {
    'uk': 'Українська',
    'en': 'English',
    'pl': 'Polski',
    'pt': 'Português',
    'es': 'Español',
  };
  
  static List<String> get availableLanguages => _languageNames.values.toList();
  
  static String getLanguageCode(String languageName) {
    return _languageNames.entries.firstWhere(
      (entry) => entry.value == languageName,
      orElse: () => const MapEntry('uk', 'Українська'),
    ).key;
  }
  
  static String getLanguageName(String languageCode) {
    return _languageNames[languageCode] ?? 'Українська';
  }
  
  LanguageProvider() {
    _loadLanguage();
  }
  
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'uk';
      _currentLocale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      // Якщо помилка, використовуємо українську
      _currentLocale = const Locale('uk');
    }
  }
  
  Future<void> changeLanguage(String languageName) async {
    final languageCode = getLanguageCode(languageName);
    if (languageCode != _currentLocale.languageCode) {
      _currentLocale = Locale(languageCode);
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, languageCode);
      } catch (e) {
        // Ігноруємо помилки збереження
      }
      
      notifyListeners();
    }
  }
  
  Future<void> changeLanguageByCode(String languageCode) async {
    if (languageCode != _currentLocale.languageCode) {
      _currentLocale = Locale(languageCode);
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, languageCode);
      } catch (e) {
        // Ігноруємо помилки збереження
      }
      
      notifyListeners();
    }
  }
} 