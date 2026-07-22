import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/panel_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

Paciente _paciente() => Paciente(
  id: '11111111-1111-1111-1111-111111111111',
  nombre: 'Ana',
  apellido: 'Rodríguez',
  birthDate: DateTime(1990, 5, 12),
  govID: '001-1234567-8',
  contactos: const [],
  estatus: EstatusPersona.activo,
  genero: Genero.femenino,
  trabajo: 'Docente',
  referencia: 'Campaña',
  citas: const [],
  tipoPaciente: TipoPaciente.integrado,
  record: Record(
    pacienteId: '11111111-1111-1111-1111-111111111111',
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const ['Extracción de cordales'],
    historialFamiliar: 'Diabetes por línea materna',
  ),
);

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: inner!,
  ),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('como barra lateral conserva sus 300 px de escritorio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(PanelPaciente(paciente: _paciente())));

    // 300 de tarjeta + los 12 de margen izquierdo frente al workspace.
    expect(tester.getSize(find.byType(PanelPaciente)).width, 312);
    expect(tester.takeException(), isNull);
  });

  for (final ancho in [320.0, 360.0, 390.0]) {
    testWidgets('como panel embebido ocupa los ${ancho.toInt()} px del cajón', (
      tester,
    ) async {
      tester.view.physicalSize = Size(ancho, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(PanelPaciente(paciente: _paciente(), asSidebar: false)),
      );

      expect(tester.getSize(find.byType(PanelPaciente)).width, ancho);
      expect(
        tester.takeException(),
        isNull,
        reason: 'la ficha del paciente no debe desbordar en $ancho px',
      );
    });
  }

  testWidgets('la ficha resiste el texto ampliado en 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        PanelPaciente(paciente: _paciente(), asSidebar: false),
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
