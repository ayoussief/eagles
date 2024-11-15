import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale;

  LanguageProvider(String initialLanguage) : _locale = Locale(initialLanguage);

  Locale get locale => _locale;

  void setLocale(String languageCode) {
    _locale = Locale(languageCode);
    notifyListeners();
  }
}
