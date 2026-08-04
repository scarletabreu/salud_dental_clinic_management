import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ajustes de la app.
///
/// Es [Equatable] por una razón de rendimiento, no de estilo: este estado lo
/// escucha el `MaterialApp` de `main.dart`, que es la raíz de todo el árbol.
/// Sin igualdad por valor, cada `emit` produce un objeto distinto y bloc
/// reconstruye la aplicación entera —shell, pantalla activa y listas— aunque
/// el tema no haya cambiado. Cambiar el idioma repintaba todo por nada.
class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final String languageCode;

  const SettingsState({required this.themeMode, required this.languageCode});

  SettingsState copyWith({ThemeMode? themeMode, String? languageCode}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  List<Object?> get props => [themeMode, languageCode];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit()
    : super(
        const SettingsState(themeMode: ThemeMode.system, languageCode: 'es'),
      ) {
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
