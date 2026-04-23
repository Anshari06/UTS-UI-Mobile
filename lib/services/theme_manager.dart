import 'package:flutter/foundation.dart';

class ThemeManager extends ChangeNotifier {
  ThemeManager._internal();

  static final ThemeManager _instance = ThemeManager._internal();

  static ThemeManager get instance => _instance;

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}
