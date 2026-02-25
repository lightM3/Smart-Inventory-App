import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  String _languageCode = 'tr';

  bool get isDarkMode => _isDarkMode;
  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);

  SettingsProvider() {
    _loadFromPrefs();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners(); // UI'ı hemen güncelle
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> changeLanguage(String lang) async {
    _languageCode = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', lang);
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _languageCode = prefs.getString('languageCode') ?? 'tr';
    notifyListeners();
  }
}
