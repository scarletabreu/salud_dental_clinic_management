import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/linea_tiempo_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/panel_detalle_pieza.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

DiagnosticoAplicado _hallazgo({
  String consultaId = 'c-enero',
  DateTime? fecha,
  String notas = 'Cara oclusal reblandecida',
}) => DiagnosticoAplicado(
  id: 'da-1',
  diagnosisId: 'dx',
  severidad: SeveridadDiagnosis.moderada,
  fechaAplicacion: fecha ?? DateTime(2026, 1, 10),
  notas: notas,
  consultaId: consultaId,
  superficie: TipoSuperficie.oclusal,
  doctorId: 'doc-1',
  nombreDiagnostico: 'Caries oclusal',
  claveOdontograma: 'cariada',
);

TratamientoAplicado _ejecucion({
  String id = 'ta-1',
  String consultaId = 'c-junio',
  DateTime? fecha,
  DateTime? anuladoEn,
  double? precio = 1500,
}) => TratamientoAplicado(
  id: id,
  tratamientoId: 't-1',
  esContinuo: false,
  estaTerminado: true,
  consultaId: consultaId,
  superficie: TipoSuperficie.oclusal,
  precioAplicado: precio,
  nombreTratamiento: 'Resina compuesta',
  fechaAplicacion: fecha ?? DateTime(2026, 6, 12),
  doctorEjecutaId: 'doc-1',
  anuladoEn: anuladoEn,
);

HistorialPiezas _historial({DateTime? anulacion}) => HistorialPiezas.consolidar(
  diagnosticos: {
    36: [_hallazgo()],
  },
  tratamientos: {
    36: [_ejecucion(anuladoEn: anulacion)],
  },
  consultas: {
    'c-enero': ReferenciaConsulta(
      id: 'c-enero',
      fecha: DateTime(2026, 1, 10),
      motivo: 'Dolor al masticar',
      tipoAtencion: TipoAtencionClinica.evaluacion,
      doctorId: 'doc-1',
    ),
    'c-junio': ReferenciaConsulta(
      id: 'c-junio',
      fecha: DateTime(2026, 6, 12),
      motivo: 'Restauración',
      doctorId: 'doc-1',
    ),
  },
  nombrePorDoctorId: const {'doc-1': 'Dr. Ana Pérez'},
);

Future<void> _montar(WidgetTester tester, Widget hijo) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(child: SizedBox(width: 400, child: hijo)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('LineaTiempoPieza', () {
    testWidgets('cuenta cada visita con su fecha, tipo, doctor y motivo', (
      tester,
    ) async {
      final historial = _historial();
      await _montar(
        tester,
        LineaTiempoPieza(
          historial: historial[36]!,
          nombreDoctor: historial.nombreDoctor,
        ),
      );

      expect(
        find.text('12 Jun 2026 · Consulta · Dr. Ana Pérez'),
        findsOneWidget,
      );
      expect(
        find.text('10 Ene 2026 · Evaluación · Dr. Ana Pérez'),
        findsOneWidget,
      );
      expect(find.text('Dolor al masticar'), findsOneWidget);
      expect(find.text('Restauración'), findsOneWidget);
    });

    testWidgets('cada evento lleva cara, estado, notas y precio', (
      tester,
    ) async {
      final historial = _historial();
      await _montar(tester, LineaTiempoPieza(historial: historial[36]!));

      expect(find.text('Resina compuesta · Oclusal'), findsOneWidget);
      expect(find.text('Caries oclusal · Oclusal'), findsOneWidget);
      expect(find.text('Terminado'), findsOneWidget);
      expect(find.text('Moderado'), findsOneWidget);
      expect(find.text('Cara oclusal reblandecida'), findsOneWidget);
      expect(find.text('RD\$ 1,500.00'), findsOneWidget);
    });

    testWidgets('lo anulado se conserva, tachado y rotulado', (tester) async {
      final historial = _historial(anulacion: DateTime(2026, 6, 20));
      await _montar(tester, LineaTiempoPieza(historial: historial[36]!));

      expect(find.text('Anulado'), findsOneWidget);
      final titulo = tester.widget<Text>(
        find.text('Resina compuesta · Oclusal'),
      );
      expect(titulo.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('sin historial lo dice en vez de quedarse en blanco', (
      tester,
    ) async {
      await _montar(
        tester,
        const LineaTiempoPieza(historial: HistorialPieza(fdi: 36, visitas: [])),
      );

      expect(
        find.text('Esta pieza no tiene historial registrado.'),
        findsOneWidget,
      );
    });
  });

  group('PanelDetallePieza con historial', () {
    Diente pieza() => Diente(
      odontogramaId: 'o-1',
      fdiCode: 36,
      superficies: [
        for (final tipo in TipoSuperficie.values)
          Superficie(dienteId: 'd-1', tipoSuperficie: tipo),
      ],
    );

    Future<void> montarPanel(
      WidgetTester tester, {
      required bool editMode,
      HistorialPiezas? historial,
    }) => _montar(
      tester,
      PanelDetallePieza(
        fdi: 36,
        diente: pieza(),
        editMode: editMode,
        historial: historial?[36],
        nombreDoctor: historial?.nombreDoctor,
        onClose: () {},
      ),
    );

    testWidgets('en solo lectura la línea de tiempo se abre desplegada', (
      tester,
    ) async {
      await montarPanel(tester, editMode: false, historial: _historial());

      expect(find.text('HISTORIAL DE LA PIEZA'), findsOneWidget);
      expect(find.text('2 eventos · 2 visitas'), findsOneWidget);
      expect(find.byType(LineaTiempoPieza), findsOneWidget);
    });

    testWidgets('editando arranca plegada y se abre al tocarla', (
      tester,
    ) async {
      await montarPanel(tester, editMode: true, historial: _historial());

      expect(find.byType(LineaTiempoPieza), findsNothing);
      await tester.tap(find.text('HISTORIAL DE LA PIEZA'));
      await tester.pumpAndSettle();
      expect(find.byType(LineaTiempoPieza), findsOneWidget);
    });

    testWidgets('sin historial la ficha no muestra la sección', (tester) async {
      await montarPanel(tester, editMode: false);

      expect(find.text('HISTORIAL DE LA PIEZA'), findsNothing);
    });

    testWidgets(
      'con historial los antecedentes no se repiten arriba sin fecha',
      (tester) async {
        // La ficha listaba un grupo «Histórico» sin fecha ni consulta; con la
        // línea de tiempo ese grupo sobra y solo alargaba el panel.
        final historial = _historial();
        await _montar(
          tester,
          PanelDetallePieza(
            fdi: 36,
            diente: Diente(
              odontogramaId: 'o-1',
              fdiCode: 36,
              superficies: const [],
              diagnosticosHistoricos: [_hallazgo()],
            ),
            editMode: false,
            historial: historial[36],
            onClose: () {},
          ),
        );

        expect(find.text('HISTÓRICO'), findsNothing);
      },
    );
  });
}
