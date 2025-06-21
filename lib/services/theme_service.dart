// lib/services/theme_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode { light, dark, system }

class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  /// Initialize theme service and load saved preference
  Future<void> initialize() async {
    print('🎨 [ThemeService] Initializing theme service...');
    await _loadThemeMode();
    _updateSystemBrightness();
    print('✅ [ThemeService] Theme service initialized with mode: $_themeMode');
  }

  /// Load theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeModeKey);
      
      if (savedThemeIndex != null && savedThemeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[savedThemeIndex];
        print('📂 [ThemeService] Loaded saved theme mode: $_themeMode');
      } else {
        _themeMode = ThemeMode.system; // Default to system
        print('📂 [ThemeService] No saved theme found, using system default');
      }
      
      _updateDarkModeState();
    } catch (e) {
      print('❌ [ThemeService] Error loading theme mode: $e');
      _themeMode = ThemeMode.system;
      _updateDarkModeState();
    }
  }

  /// Save theme mode to SharedPreferences
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, _themeMode.index);
      print('💾 [ThemeService] Theme mode saved: $_themeMode');
    } catch (e) {
      print('❌ [ThemeService] Error saving theme mode: $e');
    }
  }

  /// Update dark mode state based on current theme mode
  void _updateDarkModeState() {
    switch (_themeMode) {
      case ThemeMode.light:
        _isDarkMode = false;
        break;
      case ThemeMode.dark:
        _isDarkMode = true;
        break;
      case ThemeMode.system:
        _updateSystemBrightness();
        break;
    }
  }

  /// Update brightness based on system setting
  void _updateSystemBrightness() {
    if (_themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
      print('🌓 [ThemeService] System brightness: $brightness, isDark: $_isDarkMode');
    }
  }

  /// Change theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      print('🎨 [ThemeService] Changing theme mode from $_themeMode to $mode');
      _themeMode = mode;
      _updateDarkModeState();
      await _saveThemeMode();
      notifyListeners();
      
      // Update system UI overlay style
      _updateSystemUIOverlay();
    }
  }

  /// Update system UI overlay style based on current theme
  void _updateSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: _isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: _isDarkMode ? const Color(0xFF121212) : Colors.white,
        systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  /// Handle system brightness changes (for system theme mode)
  void handleSystemBrightnessChange() {
    if (_themeMode == ThemeMode.system) {
      final oldIsDarkMode = _isDarkMode;
      _updateSystemBrightness();
      
      if (oldIsDarkMode != _isDarkMode) {
        print('🌓 [ThemeService] System brightness changed, updating theme');
        _updateSystemUIOverlay();
        notifyListeners();
      }
    }
  }

  /// Get theme mode display name
  String getThemeModeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get theme mode icon
  IconData getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}