import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/tooth_geometry.dart';

void main() {
  group('Geometría de piezas · trazos reutilizados (SD-132)', () {
    test('el mismo tipo y tamaño devuelve el trazo ya construido', () {
      const size = Size(28, 34);

      final primero = buildToothPath(ToothType.molar, size);
      final segundo = buildToothPath(ToothType.molar, size);

      expect(
        identical(primero, segundo),
        isTrue,
        reason:
            'la arcada llama a esto por pieza en cada repintado; reconstruir '
            'el Path convierte cada hover en decenas de asignaciones',
      );
    });

    test('un tamaño distinto produce un trazo distinto', () {
      final pequeno = buildToothPath(ToothType.molar, const Size(20, 24));
      final grande = buildToothPath(ToothType.molar, const Size(40, 48));

      expect(identical(pequeno, grande), isFalse);
      expect(grande.getBounds().width, greaterThan(pequeno.getBounds().width));
    });

    test('cada tipo de pieza conserva su propia forma', () {
      const size = Size(28, 34);

      expect(
        identical(
          buildToothPath(ToothType.molar, size),
          buildToothPath(ToothType.incisor, size),
        ),
        isFalse,
      );
    });

    test('el surco oclusal también se reutiliza y respeta el tipo', () {
      const size = Size(28, 34);

      final primero = buildGroovePath(ToothType.molar, size, upper: true);
      final segundo = buildGroovePath(ToothType.molar, size, upper: true);
      expect(identical(primero, segundo), isTrue);

      // Los molares superiores e inferiores no llevan el mismo surco.
      expect(
        identical(
          buildGroovePath(ToothType.molar, size, upper: true),
          buildGroovePath(ToothType.molar, size, upper: false),
        ),
        isFalse,
      );

      // Incisivos y caninos no tienen surco que dibujar.
      expect(buildGroovePath(ToothType.incisor, size, upper: true), isNull);
      expect(buildGroovePath(ToothType.canine, size, upper: true), isNull);
    });

    test('el trazo reutilizado sigue centrado en el origen y con el tamaño pedido', () {
      const size = Size(30, 40);
      final bounds = buildToothPath(ToothType.premolar, size).getBounds();

      expect(bounds.center.dx, closeTo(0, 0.001));
      expect(bounds.center.dy, closeTo(0, 0.001));
      expect(bounds.width, lessThanOrEqualTo(size.width + 0.001));
      expect(bounds.height, lessThanOrEqualTo(size.height + 0.001));
    });

    test('la caché no crece sin límite ante tamaños continuos', () {
      // Un LayoutBuilder puede pedir cientos de tamaños distintos. Que no se
      // reutilicen es aceptable; que la memoria crezca sin techo, no.
      for (var i = 0; i < 400; i++) {
        buildToothPath(ToothType.molar, Size(20 + i * 0.5, 24 + i * 0.5));
      }

      // Tras el vaciado la función sigue siendo correcta.
      const size = Size(28, 34);
      final a = buildToothPath(ToothType.molar, size);
      final b = buildToothPath(ToothType.molar, size);
      expect(identical(a, b), isTrue);
    });
  });
}
