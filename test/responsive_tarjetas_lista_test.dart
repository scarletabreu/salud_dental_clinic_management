import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/widgets/cuenta_card.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/widgets/perfil_card.dart';

/// Anchos que toda tarjeta de lista tiene que aguantar.
const anchosMoviles = [320.0, 360.0, 390.0];

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: inner!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void configurarViewport(
  WidgetTester tester,
  double ancho, [
  double alto = 800,
]) {
  tester.view.physicalSize = Size(ancho, alto);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Doctor _doctor() => Doctor(
  id: '22222222-2222-2222-2222-222222222222',
  nombre: 'Bartolomé',
  apellido: 'Santana Villalona',
  birthDate: DateTime(1985, 3, 2),
  govID: '402-1234567-1',
  contactos: [
    Contacto(
      numeroTelefono: '809-555-0134',
      email: 'b.santana@clinica.do',
      direccion: 'Av. Winston Churchill 1099, Santo Domingo',
    ),
  ],
  estatus: EstatusPersona.activo,
  username: 'bsantana',
  specialty: 'Endodoncia y rehabilitación oral',
  assistants: const [],
);

Cuenta _cuenta() => Cuenta(
  id: '33333333-3333-3333-3333-333333333333',
  consultaId: '44444444-4444-4444-4444-444444444444',
  fechaCreacion: DateTime(2026, 7, 20),
  metodoPago: MetodoPago.credito,
  estado: EstadoCuenta.pendiente,
  itemCuentas: [
    ItemCuenta(
      cuentaId: '33333333-3333-3333-3333-333333333333',
      descripcion: 'Endodoncia multirradicular con reconstrucción',
      precioUnitario: 18500,
      cantidad: 2,
    ),
  ],
);

void main() {
  group('PerfilCard', () {
    for (final ancho in anchosMoviles) {
      testWidgets('no desborda en ${ancho.toInt()} px', (tester) async {
        configurarViewport(tester, ancho);
        await tester.pumpWidget(_app(PerfilCard(usuario: _doctor())));

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('no desborda con el texto al doble en 320 px', (tester) async {
      configurarViewport(tester, 320, 1400);
      await tester.pumpWidget(
        _app(PerfilCard(usuario: _doctor()), textScale: 2),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('CuentaCard', () {
    for (final ancho in anchosMoviles) {
      testWidgets('no desborda en ${ancho.toInt()} px', (tester) async {
        configurarViewport(tester, ancho);
        await tester.pumpWidget(
          _app(CuentaCard(cuenta: _cuenta(), onEliminar: () {})),
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('no desborda con el texto al doble en 320 px', (tester) async {
      configurarViewport(tester, 320, 1400);
      await tester.pumpWidget(
        _app(CuentaCard(cuenta: _cuenta()), textScale: 2),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
