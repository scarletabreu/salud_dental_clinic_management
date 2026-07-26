import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme.dart';
import 'responsive.dart';

/// Etapa del arranque que falló, que es lo que decide qué hay que corregir.
enum BootstrapErrorKind {
  /// La compilación no recibió ninguna variable `--dart-define`.
  configuracionAusente,

  /// Llegaron variables, pero alguna no supera la validación de [AppConfig].
  configuracionInvalida,

  /// La configuración era válida y falló Supabase o el contenedor de
  /// dependencias.
  inicializacion,
}

/// Pantalla que sustituye al arranque cuando `main()` no logra completarse.
///
/// Antes de SD-133 la configuración de Supabase venía compilada en `main.dart`,
/// así que el arranque no podía fallar por falta de datos. Al pasar a
/// `--dart-define`, un `flutter run` sin esas variables lanza un `StateError`
/// antes de que exista un solo widget: en web eso deja el `<body>` vacío y el
/// único rastro queda en la consola del navegador. Esta pantalla convierte ese
/// fallo mudo en un diagnóstico legible dentro de la propia aplicación.
///
/// No depende del contenedor de dependencias ni de `SettingsCubit`: se dibuja
/// justamente cuando esa inicialización no llegó a ocurrir.
class BootstrapErrorScreen extends StatelessWidget {
  const BootstrapErrorScreen({
    required this.detalle,
    required this.tipo,
    super.key,
  });

  /// Mensaje del error que impidió arrancar.
  final String detalle;

  /// Etapa que falló. Decide la explicación y si procede mostrar el comando.
  final BootstrapErrorKind tipo;

  static const _comando =
      'flutter run -d chrome \\\n'
      '  --dart-define-from-file=dart_define.json';

  String get _explicacion => switch (tipo) {
    BootstrapErrorKind.configuracionAusente =>
      'La compilación no recibió la configuración pública de Supabase. Desde '
          'SD-133 la URL y la clave se inyectan al compilar, no van en el '
          'código.',
    BootstrapErrorKind.configuracionInvalida =>
      'La configuración inyectada al compilar no es válida.',
    BootstrapErrorKind.inicializacion =>
      'La configuración es válida, pero falló la inicialización de Supabase o '
          'de las dependencias de la aplicación.',
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salud Dental',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Builder(builder: _contenido),
    );
  }

  Widget _contenido(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.bgPage,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: context.pageInsets(top: 24, bottom: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider),
                  boxShadow: [colors.cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: colors.red, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No se pudo iniciar la aplicación',
                            style: textTheme.titleLarge?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _explicacion,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Bloque(colors: colors, texto: detalle, color: colors.red),
                    if (tipo != BootstrapErrorKind.inicializacion) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Para ejecutarla en local, copia '
                        '`dart_define.example.json` a `dart_define.json`, '
                        'rellena los valores y arranca así:',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Bloque(
                        colors: colors,
                        texto: _comando,
                        color: colors.textPrimary,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'El detalle completo está en README.md y DEPLOYMENT.md.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({
    required this.colors,
    required this.texto,
    required this.color,
  });

  final AppColors colors;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.chipBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        texto,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
          color: color,
        ),
      ),
    );
  }
}
