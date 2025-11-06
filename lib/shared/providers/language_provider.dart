import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'tr'; // Default Turkish
  static const Map<String, String> _supportedLanguages = {
    'tr': 'Türkçe',
    'en': 'English',
  };

  String get currentLanguage => _currentLanguage;
  Map<String, String> get supportedLanguages => _supportedLanguages;

  void setLanguage(String languageCode) {
    if (_supportedLanguages.containsKey(languageCode)) {
      _currentLanguage = languageCode;
      notifyListeners();
    }
  }

  String getLanguageName(String languageCode) {
    return _supportedLanguages[languageCode] ?? languageCode;
  }

  bool get isTurkish => _currentLanguage == 'tr';
  bool get isEnglish => _currentLanguage == 'en';
}
