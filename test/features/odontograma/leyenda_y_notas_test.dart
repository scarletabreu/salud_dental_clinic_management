import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/leyenda_odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/paleta_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/panel_detalle_pieza.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

Diente _pieza({
  List<DiagnosticoAplicado> diagnosis = const [],
  List<TratamientoAplicado> tratamientos = const [],
  List<DiagnosticoAplicado> diagnosticosHistoricos = const [],
  String? observaciones,
}) => Diente(
  odontogramaId: 'o-1',
  fdiCode: 36,
  superficies: [
    for (final t in TipoSuperficie.values)
      Superficie(dienteId: 'd-1', tipoSuperficie: t),
  ],
  diagnosis: diagnosis,
  tratamientos: tratamientos,
  diagnosticosHistoricos: diagnosticosHistoricos,
  observaciones: observaciones,
);

DiagnosticoAplicado _caries({String? consultaId = 'c-hoy'}) =>
    DiagnosticoAplicado(
      id: 'da-1',
      diagnosisId: 'dx',
      severidad: SeveridadDiagnosis.moderada,
      fechaAplicacion: DateTime(2026, 6, 12),
      notas: '',
      consultaId: consultaId,
      superficie: TipoSuperficie.oclusal,
      doctorId: 'doc-1',
      nombreDiagnostico: 'Caries oclusal',
      claveOdontograma: 'cariada',
    );

Future<void> _montarPanel(
  WidgetTester tester, {
  required Diente diente,
  List<ItemPlanTratamiento> itemsPlan = const [],
  void Function(Diente, String)? onNotasChanged,
  String Function(String)? nombreDoctor,
  bool editMode = true,
}) async {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: PanelDetallePieza(
              fdi: 36,
              diente: diente,
              itemsPlan: itemsPlan,
              editMode: editMode,
              onClose: () {},
              onNotasChanged: onNotasChanged,
              nombreDoctor: nombreDoctor,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('leyenda del odontograma', () {
    Future<void> montarLeyenda(
      WidgetTester tester, {
      PaletaOdontodiagrama? paleta,
      List<ProcedenciaMarca> procedencias = ProcedenciaMarca.values,
    }) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: LeyendaOdontograma(
              paleta: paleta ?? PaletaOdontodiagrama.claro,
              procedencias: procedencias,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('explica los dos ejes: qué es la marca y de cuándo viene', (
      tester,
    ) async {
      await montarLeyenda(tester);

      expect(find.text('CLAVES'), findsOneWidget);
      expect(find.text('PROCEDENCIA'), findsOneWidget);
      for (final procedencia in ProcedenciaMarca.values) {
        expect(find.text(procedencia.etiqueta), findsOneWidget);
      }
      expect(find.text('Cariada'), findsOneWidget);
      expect(find.text('Restaurada'), findsOneWidget);
    });

    testWidgets('cada entrada se anuncia con su significado', (tester) async {
      final handle = tester.ensureSemantics();
      await montarLeyenda(tester);

      expect(
        find.bySemanticsLabel('Cariada, clave del odontograma'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Histórico: ${ProcedenciaMarca.historico.descripcion}',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('la hoja impresa usa la misma leyenda que la pantalla', (
      tester,
    ) async {
      await montarLeyenda(tester, paleta: PaletaOdontodiagrama.impresion);

      // Mismos rótulos, misma estructura: lo que cambia es el papel, no el
      // vocabulario con el que se explica la boca.
      expect(find.text('CLAVES'), findsOneWidget);
      expect(find.text('PROCEDENCIA'), findsOneWidget);
      expect(find.text('Pérdida'), findsOneWidget);
    });

    testWidgets('una vista puede limitar las procedencias que explica', (
      tester,
    ) async {
      await montarLeyenda(
        tester,
        procedencias: const [ProcedenciaMarca.evaluado],
      );

      expect(find.text('Evaluado'), findsOneWidget);
      expect(find.text('Planificado'), findsNothing);
    });
  });

  group('ficha de la pieza', () {
    testWidgets('agrupa lo anotado por procedencia', (tester) async {
      await _montarPanel(
        tester,
        diente: _pieza(
          diagnosis: [_caries()],
          diagnosticosHistoricos: [_caries(consultaId: 'c-vieja')],
        ),
        itemsPlan: [
          ItemPlanTratamiento(
            planId: 'p-1',
            tratamientoId: 't-1',
            superficie: TipoSuperficie.vestibular,
            estado: EstadoItemPlan.aceptado,
            fechaPropuesta: DateTime(2026, 7, 20),
            nombreTratamiento: 'Corona',
          ),
        ],
      );

      expect(find.text('EVALUADO'), findsOneWidget);
      expect(find.text('PLANIFICADO'), findsOneWidget);
      expect(find.text('HISTÓRICO'), findsOneWidget);
      expect(find.text('Corona · Vestibular'), findsOneWidget);
    });

    testWidgets('muestra el doctor cuando se sabe su nombre', (tester) async {
      await _montarPanel(
        tester,
        diente: _pieza(diagnosis: [_caries()]),
        nombreDoctor: (id) => id == 'doc-1' ? 'Dr. Pérez' : '',
      );

      expect(find.textContaining('Dr. Pérez'), findsOneWidget);
    });

    testWidgets('sin resolver el nombre no se enseña el identificador', (
      tester,
    ) async {
      await _montarPanel(tester, diente: _pieza(diagnosis: [_caries()]));

      expect(find.textContaining('doc-1'), findsNothing);
    });

    testWidgets('las notas de la pieza se escriben y se emiten', (
      tester,
    ) async {
      String? anotado;
      await _montarPanel(
        tester,
        diente: _pieza(),
        onNotasChanged: (_, texto) => anotado = texto,
      );

      await tester.enterText(
        find.byKey(const ValueKey('notas_pieza')),
        'Sensibilidad al frío',
      );
      await tester.pump();

      expect(anotado, 'Sensibilidad al frío');
    });

    testWidgets('sin permiso de edición las notas se leen pero no se editan', (
      tester,
    ) async {
      await _montarPanel(
        tester,
        diente: _pieza(observaciones: 'Fractura de cúspide'),
        editMode: false,
      );

      expect(find.text('Fractura de cúspide'), findsOneWidget);
      expect(find.byKey(const ValueKey('notas_pieza')), findsNothing);
    });

    testWidgets('una pieza sin notas no muestra el campo en solo lectura', (
      tester,
    ) async {
      await _montarPanel(tester, diente: _pieza(), editMode: false);

      expect(find.text('NOTAS DE LA PIEZA'), findsNothing);
    });

    testWidgets('el mapa de caras se anuncia con lo que tiene cada una', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _montarPanel(tester, diente: _pieza(diagnosis: [_caries()]));

      expect(
        find.bySemanticsLabel(
          RegExp(r'Caras del diente 36\..*Oclusal: Caries oclusal, evaluado'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
