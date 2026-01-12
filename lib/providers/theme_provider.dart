import 'package:flutter/material.dart';

/// Provider for managing application theme (light/dark mode).
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  /// Gets the current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Returns true if dark mode is enabled.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Toggles between light and dark mode.
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Sets the theme mode explicitly.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }
}
