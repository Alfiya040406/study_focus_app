import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsModel {
  final bool darkMode;
  final String fontFamily;
  final double fontScale;
  final String? defaultMethod;

  const AppSettingsModel({
    required this.darkMode,
    required this.fontFamily,
    required this.fontScale,
    this.defaultMethod,
  });

  AppSettingsModel copyWith({
    bool? darkMode,
    String? fontFamily,
    double? fontScale,
    String? defaultMethod,
  }) {
    return AppSettingsModel(
      darkMode: darkMode ?? this.darkMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontScale: fontScale ?? this.fontScale,
      defaultMethod: defaultMethod ?? this.defaultMethod,
    );
  }
}

class AppSettingsService {
  static const String _darkModeKey = 'dark_mode';
  static const String _fontFamilyKey = 'font_family';
  static const String _fontScaleKey = 'font_scale';
  static const String _defaultMethodKey = 'default_study_method';

  static final ValueNotifier<AppSettingsModel> settingsNotifier =
      ValueNotifier<AppSettingsModel>(
    const AppSettingsModel(
      darkMode: false,
      fontFamily: 'Poppins',
      fontScale: 1.0,
      defaultMethod: null,
    ),
  );

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    settingsNotifier.value = AppSettingsModel(
      darkMode: prefs.getBool(_darkModeKey) ?? false,
      fontFamily: prefs.getString(_fontFamilyKey) ?? 'Poppins',
      fontScale: prefs.getDouble(_fontScaleKey) ?? 1.0,
      defaultMethod: prefs.getString(_defaultMethodKey),
    );
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);

    settingsNotifier.value = settingsNotifier.value.copyWith(
      darkMode: value,
    );
  }

  static Future<void> setFontFamily(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, value);

    settingsNotifier.value = settingsNotifier.value.copyWith(
      fontFamily: value,
    );
  }

  static Future<void> setFontScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, value);

    settingsNotifier.value = settingsNotifier.value.copyWith(
      fontScale: value,
    );
  }

  static Future<void> setDefaultMethod(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultMethodKey, value);

    settingsNotifier.value = settingsNotifier.value.copyWith(
      defaultMethod: value,
    );
  }

  static Future<String?> getDefaultMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultMethodKey);
  }
}
