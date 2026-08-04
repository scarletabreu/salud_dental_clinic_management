import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/core/presentation/tarjeta_opcion.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/alcance_impresion_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_expediente.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

EvaluacionOdontologica _evaluacion() => EvaluacionOdontologica.vacia
    .alternar(
      16,
      EstadoClinicoDental.cariada,
      superficie: TipoSuperficie.oclusal,
    )
    .alternar(46, EstadoClinicoDental.perdida);

Widget _hoja({VoidCallback? onImprimirHistorial, String? avisoHistorial}) =>
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: OdontodiagramaExpediente(
            evaluacion: _evaluacion(),
            nombrePaciente: 'Ana Mercedes Rodríguez',
            fecha: DateTime(2026, 7, 24),
            onImprimirHistorial: onImprimirHistorial,
            avisoHistorial: avisoHistorial,
          ),
        ),
      ),
    );

Future<void> _abrirHoja(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Imprimir Odontodiagrama'));
  await tester.pumpAndSettle();
}

void main() {
  test('sin historial que ofrecer el botón no pregunta nada', () {
    // Es el caso de siempre: imprimir saca la hoja de esta consulta y punto.
    // No se pulsa el botón porque eso iría al plugin de impresión, que en un
    // test no existe; basta con que el widget declare que no hay qué elegir.
    final widget = OdontodiagramaExpediente(
      evaluacion: EvaluacionOdontologica.vacia,
      nombrePaciente: 'Ana Mercedes Rodríguez',
      fecha: DateTime(2026, 7, 24),
    );

    expect(widget.ofreceAlcance, isFalse);
  });

  testWidgets('con historial disponible se puede elegir el expediente entero', (
    tester,
  ) async {
    var impresionesDelHistorial = 0;
    await tester.pumpWidget(
      _hoja(onImprimirHistorial: () => impresionesDelHistorial++),
    );
    await _abrirHoja(tester);

    expect(find.text('¿Qué deseas imprimir?'), findsOneWidget);
    expect(find.text('Solo esta consulta'), findsOneWidget);
    expect(find.text('Historial clínico completo'), findsOneWidget);

    await tester.tap(find.byKey(HojaAlcanceImpresion.keyHistorial));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HojaAlcanceImpresion.keyContinuar));
    await tester.pumpAndSettle();

    expect(impresionesDelHistorial, 1);
    expect(find.text('¿Qué deseas imprimir?'), findsNothing);
  });

  testWidgets('cancelar no imprime nada', (tester) async {
    var impresionesDelHistorial = 0;
    await tester.pumpWidget(
      _hoja(onImprimirHistorial: () => impresionesDelHistorial++),
    );
    await _abrirHoja(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(impresionesDelHistorial, 0);
    expect(find.text('¿Qué deseas imprimir?'), findsNothing);
  });

  testWidgets('un historial no disponible se explica en vez de esconderse', (
    tester,
  ) async {
    await tester.pumpWidget(
      _hoja(avisoHistorial: 'El historial del paciente no se pudo cargar.'),
    );
    await _abrirHoja(tester);

    expect(
      find.text('El historial del paciente no se pudo cargar.'),
      findsOneWidget,
    );

    // Ofrecida pero inerte: pulsarla no cambia la elección, que sigue siendo
    // la consulta abierta.
    final opcion = tester.widget<TarjetaOpcion>(
      find.byKey(HojaAlcanceImpresion.keyHistorial),
    );
    expect(opcion.onTap, isNull);

    final consulta = tester.widget<TarjetaOpcion>(
      find.byKey(HojaAlcanceImpresion.keyConsulta),
    );
    expect(consulta.seleccionada, isTrue);
  });
}
