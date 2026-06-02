/// Utilidades de validación para el sistema clínico.
///
/// Contiene validadores reutilizables para campos críticos del formulario,
/// incluyendo el validador de cédula según el algoritmo oficial de la JCE.
library validators;

// ─────────────────────────────────────────────────────────────────────────────
// VALIDACIÓN DE CÉDULA (Algoritmo JCE / Módulo 10 / Luhn)
// ─────────────────────────────────────────────────────────────────────────────

/// Valida una cédula dominicana usando el algoritmo oficial de la
/// Junta Central Electoral (JCE), basado en el método Módulo 10 (Luhn).
///
/// Acepta el número con o sin guiones y espacios.
///
/// ### Ejemplos de uso
/// ```dart
/// isValidCedula('00113918205')  // true  – cédula real válida
/// isValidCedula('001-1391820-5') // true  – con guiones, válida
/// isValidCedula('12345678901')  // false – dígito verificador incorrecto
/// isValidCedula('123abc')       // false – contiene letras
/// ```
///
/// Retorna `true` si la cédula es lógicamente válida según el algoritmo JCE.
bool isValidCedula(String cedula) {
  // 1. Limpiar guiones, espacios y cualquier separador visual.
  final String cleaned = cedula.replaceAll(RegExp(r'[\s\-]'), '');

  // 2. Debe tener exactamente 11 dígitos y no contener letras ni símbolos.
  if (cleaned.length != 11) return false;
  if (!RegExp(r'^\d{11}$').hasMatch(cleaned)) return false;

  // 3. Aplicar el algoritmo Módulo 10 (Luhn adaptado JCE).
  //
  //    Posiciones indexadas desde 0 (izquierda a derecha):
  //      • Índice par  (0, 2, 4, …) → multiplicar por 1
  //      • Índice impar(1, 3, 5, …) → multiplicar por 2
  //
  //    Si el producto ≥ 10, sumar sus dos dígitos (equivale a producto - 9).
  //    Sumar todos los resultados; es válida si el total es múltiplo de 10.

  const List<int> multipliers = [1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1];
  int total = 0;

  for (int i = 0; i < 11; i++) {
    int digit = int.parse(cleaned[i]);
    int product = digit * multipliers[i];

    // Si el producto es ≥ 10, sumar sus dígitos (p.ej. 14 → 1+4 = 5).
    if (product >= 10) {
      product = (product ~/ 10) + (product % 10);
    }

    total += product;
  }

  return total % 10 == 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// VALIDATOR PARA FORMULARIOS FLUTTER (FormField / TextFormField)
// ─────────────────────────────────────────────────────────────────────────────

/// Mensaje de error estándar que se muestra al usuario cuando la cédula
/// no supera la validación.
const String kCedulaErrorMessage = 'Cédula inválida. Verifique los números.';

/// Validador listo para usar en [TextFormField.validator].
///
/// Retorna `null` si el valor es válido (sin error).
/// Retorna [kCedulaErrorMessage] si el valor es nulo, vacío o no pasa el
/// algoritmo JCE.
///
/// ### Ejemplo de integración en un formulario
/// ```dart
/// TextFormField(
///   decoration: const InputDecoration(labelText: 'Cédula'),
///   inputFormatters: [CedulaInputFormatter()],
///   validator: cedulaValidator,
///   keyboardType: TextInputType.number,
/// )
/// ```
String? cedulaValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El número de cédula es requerido.';
  }
  if (!isValidCedula(value)) {
    return kCedulaErrorMessage;
  }
  return null; // válido
}