import 'package:flutter/foundation.dart';

/// Único punto de salida de diagnóstico de la app.
///
/// En release `kDebugMode` es una constante `false`, así que el compilador
/// elimina tanto la llamada como la interpolación del mensaje. Esto importa:
/// un `debugPrint('... $lista')` suelto sigue construyendo el string en
/// release y, dentro de un bucle de ensamblado o de un `build`, ese coste se
/// paga en cada frame aunque nadie lea la consola.
///
/// Por eso los mensajes se pasan como *callback* y no como `String` ya
/// formado: sin `kDebugMode` no se evalúa nada.
abstract final class AppLog {
  static final _uuid = RegExp(
    r'\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b',
    caseSensitive: false,
  );

  static String _contextoSeguro(String contexto) =>
      contexto.replaceAll(_uuid, '<uuid>');

  /// Traza de desarrollo. Desaparece por completo en release.
  static void debug(String Function() mensaje) {
    if (kDebugMode) debugPrint(mensaje());
  }

  /// Error recuperable que no interrumpe al usuario pero conviene ver mientras
  /// se desarrolla. También desaparece en release: lo que el usuario debe
  /// notar viaja por `Failure`, no por la consola.
  static void error(String contexto, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[${_contextoSeguro(contexto)}] error=${error.runtimeType}');
    }
  }
}
