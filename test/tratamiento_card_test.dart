import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/widgets/tratamiento_card.dart';
import 'package:salud_dental_clinic_management/shell/shell_destination.dart';

final _tratamiento = Tratamiento(
  id: 't1',
  nombre: 'Aplicación de flúor',
  descripcion: 'Tratamiento preventivo de remineralización.',
  costo: 1200,
  contraindicaciones: const [],
  alcance: Alcance.global,
);

Widget _card(double width) => MaterialApp(
  // The card reads AppColors off the theme extension, so the real theme is
  // required rather than the bare default.
  theme: AppTheme.light,
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: TratamientoCard(tratamiento: _tratamiento, onEdit: () {}),
      ),
    ),
  ),
);

void main() {
  group('TratamientoCard', () {
    for (final width in <double>[320, 360, 390]) {
      testWidgets('keeps the name on one line at ${width.toInt()} px', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_card(width));
        expect(tester.takeException(), isNull);

        // The desktop row squeezed the name to zero width, which made it wrap
        // one character per line. Anything near the full card width is fine.
        final name = find.text(_tratamiento.nombre);
        expect(name, findsOneWidget);
        expect(tester.getSize(name).width, greaterThan(width * 0.5));
      });
    }

    testWidgets('keeps the single-row layout when there is room', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_card(900));
      expect(tester.takeException(), isNull);

      final name = tester.getRect(find.text(_tratamiento.nombre));
      final price = tester.getRect(find.text('\$1200.00'));
      expect(price.center.dy, closeTo(name.center.dy, 40));
    });
  });

  test('no destination is reachable before the roles arrive', () {
    // The shell renders once with an empty role list right after login, so it
    // must cope with an empty destination list instead of indexing into it.
    for (final label in const [
      'Inicio',
      'Pacientes',
      'Caja',
      'Configuración',
    ]) {
      expect(
        ShellDestinationAccess.allows(label, const <RolUsuario>[]),
        isFalse,
      );
    }
  });
}
