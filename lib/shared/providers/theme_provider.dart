import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

enum AppThemeMode { light, dark }

enum AppLanguage { turkish, english }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _currentTheme = AppThemeMode.light;
  AppLanguage _currentLanguage = AppLanguage.turkish;

  AppThemeMode get currentTheme => _currentTheme;
  AppLanguage get currentLanguage => _currentLanguage;

  bool get isDarkMode => _currentTheme == AppThemeMode.dark;
  bool get isTurkish => _currentLanguage == AppLanguage.turkish;

  // Theme colors getter
  Color get backgroundColor =>
      isDarkMode ? AppColors.darkBackground : AppColors.background;
  Color get foregroundColor =>
      isDarkMode ? AppColors.darkForeground : AppColors.foreground;
  Color get cardBackground =>
      isDarkMode ? AppColors.darkCardBackground : AppColors.cardBackground;
  Color get cardForeground =>
      isDarkMode ? AppColors.darkCardForeground : AppColors.cardForeground;
  Color get primaryColor =>
      isDarkMode ? AppColors.darkPrimary : AppColors.primary;
  Color get primaryForegroundColor => isDarkMode
      ? AppColors.darkPrimaryForeground
      : AppColors.primaryForeground;
  Color get secondaryColor =>
      isDarkMode ? AppColors.darkSecondary : AppColors.secondary;
  Color get secondaryForegroundColor => isDarkMode
      ? AppColors.darkSecondaryForeground
      : AppColors.secondaryForeground;
  Color get mutedColor => isDarkMode ? AppColors.darkMuted : AppColors.muted;
  Color get mutedForegroundColor =>
      isDarkMode ? AppColors.darkMutedForeground : AppColors.mutedForeground;
  Color get borderColor => isDarkMode ? AppColors.darkBorder : AppColors.border;
  Color get inputColor => isDarkMode ? AppColors.darkInput : AppColors.input;

  // Gradient getters
  LinearGradient get homeBackgroundGradient => isDarkMode
      ? AppColors.darkHomeBackgroundGradient
      : AppColors.homeBackgroundGradient;

  LinearGradient get sleepBackgroundGradient => isDarkMode
      ? AppColors.darkSleepBackgroundGradient
      : AppColors.sleepBackgroundGradient;

  LinearGradient get feedingBackgroundGradient => isDarkMode
      ? AppColors.darkFeedingBackgroundGradient
      : AppColors.feedingBackgroundGradient;

  LinearGradient get chartsBackgroundGradient => isDarkMode
      ? AppColors.darkChartsBackgroundGradient
      : AppColors.chartsBackgroundGradient;

  LinearGradient get settingsBackgroundGradient => isDarkMode
      ? AppColors.darkSettingsBackgroundGradient
      : AppColors.settingsBackgroundGradient;

  LinearGradient get primaryGradient =>
      isDarkMode ? AppColors.darkPrimaryGradient : AppColors.primaryGradient;

  LinearGradient get cardGradient =>
      isDarkMode ? AppColors.darkCardGradient : AppColors.cardGradient;

  // Baby colors getters
  Color getBabyColor(String gender) {
    if (isDarkMode) {
      return gender == 'female'
          ? AppColors.darkBabyPink
          : AppColors.darkBabyBlue;
    } else {
      return gender == 'female' ? AppColors.babyPink : AppColors.babyBlue;
    }
  }

  LinearGradient getBabyGradient(String gender) {
    if (isDarkMode) {
      return gender == 'female'
          ? LinearGradient(
              colors: [AppColors.darkBabyPink, AppColors.darkAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [AppColors.darkBabyBlue, AppColors.darkPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
    } else {
      return gender == 'female'
          ? AppColors.babyPinkGradient
          : AppColors.babyBlueGradient;
    }
  }

  // Theme switching
  Future<void> setTheme(AppThemeMode theme) async {
    _currentTheme = theme;
    notifyListeners();

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme.name);
  }

  // Language switching
  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    notifyListeners();

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language.name);
  }

  // Load saved preferences
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme
    final themeString = prefs.getString('theme');
    if (themeString != null) {
      _currentTheme = AppThemeMode.values.firstWhere(
        (theme) => theme.name == themeString,
        orElse: () => AppThemeMode.light,
      );
    }

    // Load language
    final languageString = prefs.getString('language');
    if (languageString != null) {
      _currentLanguage = AppLanguage.values.firstWhere(
        (language) => language.name == languageString,
        orElse: () => AppLanguage.turkish,
      );
    }

    notifyListeners();
  }

  // Toggle theme
  Future<void> toggleTheme() async {
    await setTheme(isDarkMode ? AppThemeMode.light : AppThemeMode.dark);
  }

  // Toggle language
  Future<void> toggleLanguage() async {
    await setLanguage(isTurkish ? AppLanguage.english : AppLanguage.turkish);
  }

  // Get theme display name
  String getThemeDisplayName() {
    return isDarkMode ? 'Koyu Tema' : 'Açık Tema';
  }

  // Get language display name
  String getLanguageDisplayName() {
    return isTurkish ? 'Türkçe' : 'English';
  }

  // Get theme icon
  IconData getThemeIcon() {
    return isDarkMode ? Icons.dark_mode : Icons.light_mode;
  }

  // Get language icon
  IconData getLanguageIcon() {
    return isTurkish ? Icons.flag : Icons.language;
  }
}
