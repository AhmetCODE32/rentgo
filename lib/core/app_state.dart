import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String _city = 'Gaziantep';
  bool _isOwner = false;
  ThemeMode _themeMode = ThemeMode.system;

  String get city => _city;
  bool get isOwner => _isOwner;
  ThemeMode get themeMode => _themeMode;

  void setCity(String value) {
    _city = value;
    notifyListeners();
  }

  void toggleUserType(bool value) {
    _isOwner = value;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
