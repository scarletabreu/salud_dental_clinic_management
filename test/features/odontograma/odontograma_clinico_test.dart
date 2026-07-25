import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/models/odontograma_model.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontograma_clinico_widget.dart';

void main() {
  test('serializa y recupera hallazgos y tejidos blandos', () {
    final odontograma = Odontograma(
      consultaId: 'consulta-1',
      dientes: const [],
      hallazgos: const {
        16: HallazgoDental(estado: EstadoClinicoDental.caries),
        51: HallazgoDental(
          estado: EstadoClinicoDental.otro,
          detalle: 'Hipoplasia',
        ),
      },
      tejidosBlandos: const {
        TejidoBlando.lengua: EvaluacionTejidoBlando(
          condicion: CondicionTejidoBlando.conAlteracion,
          observacion: 'Lesión lateral',
        ),
      },
    );

    final parsed = OdontogramaModel.fromJson({
      'consulta_id': 'consulta-1',
      'evaluacion_clinica': odontograma.evaluacionToJson(),
    });

    expect(parsed.hallazgos[16]?.estado, EstadoClinicoDental.caries);
    expect(parsed.hallazgos[51]?.detalle, 'Hipoplasia');
    expect(
      parsed.tejidosBlandos[TejidoBlando.lengua]?.condicion,
      CondicionTejidoBlando.conAlteracion,
    );
  });

  testWidgets('permite marcar piezas FDI y alternar dentición y tejidos', (
    tester,
  ) async {
    var odontograma = Odontograma(consultaId: 'consulta-1', dientes: const []);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => OdontogramaClinicoWidget(
              odontograma: odontograma,
              editable: true,
              onHallazgosChanged: (hallazgos) => setState(
                () => odontograma = odontograma.copyWith(hallazgos: hallazgos),
              ),
              onTejidosChanged: (tejidos) => setState(
                () =>
                    odontograma = odontograma.copyWith(tejidosBlandos: tejidos),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('pieza_fdi_11')));
    await tester.pump();
    expect(odontograma.hallazgos[11]?.estado, EstadoClinicoDental.caries);

    await tester.tap(find.text('Temporal'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pieza_fdi_51')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tejido_lengua')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alterado'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(
      odontograma.tejidosBlandos[TejidoBlando.lengua]?.condicion,
      CondicionTejidoBlando.conAlteracion,
    );
  });

  testWidgets('la leyenda es configurable y la vista admite impresión', (
    tester,
  ) async {
    const leyenda = [
      EntradaLeyendaOdontograma(
        estado: EstadoClinicoDental.otro,
        color: Colors.orange,
        icon: Icons.star,
        etiqueta: 'Control especial',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: OdontogramaClinicoWidget(
              odontograma: Odontograma(
                consultaId: 'consulta-1',
                dientes: const [],
              ),
              modoImpresion: true,
              leyenda: leyenda,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Control especial'), findsOneWidget);
    expect(find.text('Permanente'), findsNothing);
  });

  testWidgets('no desborda en una evaluación de 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: OdontogramaClinicoWidget(
              odontograma: Odontograma(
                consultaId: 'consulta-1',
                dientes: const [],
              ),
              editable: true,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Temporal'), findsOneWidget);
  });
}
