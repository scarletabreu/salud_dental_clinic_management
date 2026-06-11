import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String languageCode;

  SettingsState({required this.themeMode, required this.languageCode});

  SettingsState copyWith({ThemeMode? themeMode, String? languageCode}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit()
    : super(SettingsState(themeMode: ThemeMode.system, languageCode: 'es')) {
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    final lang = prefs.getString('lang_code') ?? 'es';

    emit(
      SettingsState(
        themeMode: ThemeMode.values[themeIndex],
        languageCode: lang,
      ),
    );
  }

  void updateThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  void updateLanguage(String langCode) async {
    emit(state.copyWith(languageCode: langCode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang_code', langCode);
  }
}
