// Importa la utilidad. Ajusta la ruta según la estructura de tu proyecto.
import 'package:salud_dental_clinic_management/core/util/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidCedula – Algoritmo JCE (Módulo 10)', () {
    // ── Casos VÁLIDOS ────────────────────────────────────────────────────────

    test('Cédula real válida sin guiones: 00113918205', () {
      expect(isValidCedula('00113918205'), isTrue);
    });

    test('Cédula real válida con guiones: 001-1391820-5', () {
      expect(isValidCedula('001-1391820-5'), isTrue);
    });

    test('Cédula real válida con espacios: 001 1391820 5', () {
      expect(isValidCedula('001 1391820 5'), isTrue);
    });

    test('Segunda cédula válida generada: 40202685042', () {
      // Cédula generada con el algoritmo JCE, dígito verificador = 2.
      expect(isValidCedula('40202685042'), isTrue);
    });

    test('Segunda cédula válida con guiones: 402-0268504-2', () {
      expect(isValidCedula('402-0268504-2'), isTrue);
    });

    // ── Casos INVÁLIDOS – dígito verificador incorrecto ──────────────────────

    test('Cédula inventada (dígito verificador incorrecto): 12345678901', () {
      expect(isValidCedula('12345678901'), isFalse);
    });

    test('Cédula inventada con dígito alterado: 00113918206', () {
      // Se cambia el último dígito de la cédula válida 00113918205 → 6.
      expect(isValidCedula('00113918206'), isFalse);
    });

    test('Todos los dígitos iguales a cero pasan el algoritmo Luhn: 00000000000', () {
      // Matemáticamente 0×n = 0, suma total = 0, que es múltiplo de 10.
      // El algoritmo JCE no define una regla adicional para rechazar este
      // patrón, pero en producción se puede agregar una validación de rango
      // de provincia (primeros 3 dígitos válidos: 001-032) si se requiere.
      expect(isValidCedula('00000000000'), isTrue);
    });

    test('Todos los dígitos iguales a uno: 11111111111', () {
      expect(isValidCedula('11111111111'), isFalse);
    });

    // ── Casos INVÁLIDOS – longitud incorrecta ────────────────────────────────

    test('Menos de 11 dígitos: 0011391820', () {
      expect(isValidCedula('0011391820'), isFalse);
    });

    test('Más de 11 dígitos: 001139182050', () {
      expect(isValidCedula('001139182050'), isFalse);
    });

    test('String vacío', () {
      expect(isValidCedula(''), isFalse);
    });

    test('Un solo dígito: 5', () {
      expect(isValidCedula('5'), isFalse);
    });

    // ── Casos INVÁLIDOS – caracteres no numéricos ────────────────────────────

    test('Contiene letras: 001ABC18205', () {
      expect(isValidCedula('001ABC18205'), isFalse);
    });

    test('Solo letras: ABCDEFGHIJK', () {
      expect(isValidCedula('ABCDEFGHIJK'), isFalse);
    });

    test('Contiene caracteres especiales: 001@391820!', () {
      expect(isValidCedula('001@391820!'), isFalse);
    });

    test('Número con punto decimal: 0011391820.5', () {
      // El punto no es un separador válido; no debe limpiar y quedar en 11.
      expect(isValidCedula('0011391820.5'), isFalse);
    });
  });

  // ── Tests del validador de formulario ─────────────────────────────────────

  group('cedulaValidator – integración con FormField', () {
    test('Retorna null para cédula válida', () {
      expect(cedulaValidator('00113918205'), isNull);
    });

    test('Retorna mensaje de error para cédula inválida', () {
      expect(
        cedulaValidator('12345678901'),
        equals(kCedulaErrorMessage),
      );
    });

    test('Retorna mensaje de "requerido" para valor nulo', () {
      expect(cedulaValidator(null), contains('requerido'));
    });

    test('Retorna mensaje de "requerido" para string vacío', () {
      expect(cedulaValidator(''), contains('requerido'));
    });

    test('Retorna mensaje de "requerido" para string con solo espacios', () {
      expect(cedulaValidator('   '), contains('requerido'));
    });
  });
}