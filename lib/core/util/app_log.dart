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
  /// Traza de desarrollo. Desaparece por completo en release.
  static void debug(String Function() mensaje) {
    if (kDebugMode) debugPrint(mensaje());
  }

  /// Error recuperable que no interrumpe al usuario pero conviene ver mientras
  /// se desarrolla. También desaparece en release: lo que el usuario debe
  /// notar viaja por `Failure`, no por la consola.
  static void error(String contexto, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[$contexto] $error');
      if (stack != null) debugPrint('$stack');
    }
  }
}
