import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, dark, matrix, highContrast, ocean }

class ThemeProvider with ChangeNotifier {
  AppTheme _currentTheme = AppTheme.dark;
  ThemeData? _themeData;

  AppTheme get currentTheme => _currentTheme;
  ThemeData get themeData => _themeData ?? _buildTheme(AppTheme.dark);

  ThemeProvider() {
    _loadTheme();
  }

  void setTheme(AppTheme theme) async {
    _currentTheme = theme;
    _themeData = _buildTheme(theme);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_index', theme.index);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('theme_index') ?? AppTheme.dark.index;
    _currentTheme = AppTheme.values[index];
    _themeData = _buildTheme(_currentTheme);
    notifyListeners();
  }

  ThemeData _buildTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          cardColor: Colors.grey[200],
          primaryColor: Colors.blue,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black87),
          ),
        );
      case AppTheme.dark:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          cardColor: const Color(0xFF1E293B),
          primaryColor: Colors.blueAccent,
        );
      case AppTheme.matrix:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          cardColor: const Color(0xFF001100),
          primaryColor: Colors.greenAccent,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.greenAccent),
            bodyMedium: TextStyle(color: Colors.greenAccent),
          ),
          iconTheme: const IconThemeData(color: Colors.greenAccent),
        );
      case AppTheme.highContrast:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          cardColor: Colors.grey[900],
          primaryColor: Colors.yellow,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.yellow),
            bodyMedium: TextStyle(color: Colors.yellow),
          ),
          iconTheme: const IconThemeData(color: Colors.yellow),
        );
      case AppTheme.ocean:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF003049),
          cardColor: const Color(0xFF005073),
          primaryColor: Colors.cyanAccent,
        );
    }
  }
}