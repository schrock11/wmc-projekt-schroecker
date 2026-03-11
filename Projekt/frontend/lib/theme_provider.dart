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
        const primary = Colors.blue;
        const onPrimary = Colors.white;
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          cardColor: Colors.grey[200],
          primaryColor: primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.light,
            primary: primary,
            onPrimary: onPrimary,
          ),
          bottomAppBarTheme: const BottomAppBarThemeData(
            color: Color(0xFFF1F5F9),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: primary,
            foregroundColor: onPrimary,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black87),
          ),
        );
      case AppTheme.dark:
        const primary = Colors.blueAccent;
        const onPrimary = Colors.white;
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          cardColor: const Color(0xFF1E293B),
          primaryColor: primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.dark,
            primary: primary,
            onPrimary: onPrimary,
          ),
          bottomAppBarTheme: const BottomAppBarThemeData(
            color: Color(0xFF1E293B),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: primary,
            foregroundColor: onPrimary,
          ),
        );
      case AppTheme.matrix:
        const primary = Colors.greenAccent;
        const onPrimary = Colors.black;
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          cardColor: const Color(0xFF001100),
          primaryColor: primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.dark,
            primary: primary,
            onPrimary: onPrimary,
          ),
          bottomAppBarTheme: const BottomAppBarThemeData(
            color: Color(0xFF001100),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: primary,
            foregroundColor: onPrimary,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.greenAccent),
            bodyMedium: TextStyle(color: Colors.greenAccent),
          ),
          iconTheme: const IconThemeData(color: Colors.greenAccent),
        );
      case AppTheme.highContrast:
        const primary = Colors.yellow;
        const onPrimary = Colors.black;
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          cardColor: Colors.grey[900],
          primaryColor: primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.dark,
            primary: primary,
            onPrimary: onPrimary,
          ),
          bottomAppBarTheme: BottomAppBarThemeData(color: Colors.grey[900]),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: primary,
            foregroundColor: onPrimary,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.yellow),
            bodyMedium: TextStyle(color: Colors.yellow),
          ),
          iconTheme: const IconThemeData(color: Colors.yellow),
        );
      case AppTheme.ocean:
        const primary = Colors.cyanAccent;
        const onPrimary = Colors.black;
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF003049),
          cardColor: const Color(0xFF005073),
          primaryColor: primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.dark,
            primary: primary,
            onPrimary: onPrimary,
          ),
          bottomAppBarTheme: const BottomAppBarThemeData(
            color: Color(0xFF005073),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: primary,
            foregroundColor: onPrimary,
          ),
        );
    }
  }
}
