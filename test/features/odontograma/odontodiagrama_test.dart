import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/dientes_iniciales.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/models/odontograma_model.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/panel_detalle_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/tooth_geometry.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Lo que el diagrama pidió aplicar sobre una pieza, para poder afirmarlo sin
/// montar la consulta entera.
class PeticionPieza {
  final Diente diente;
  final TipoSuperficie? superficie;

  const PeticionPieza(this.diente, this.superficie);
}

class RegistroDiagrama {
  EvaluacionOdontologica evaluacion;
  PeticionPieza? diagnostico;
  PeticionPieza? tratamiento;
  (Diente, bool)? ausencia;

  RegistroDiagrama(this.evaluacion);
}

Diente _pieza(int fdi) =>
    Diente(odontogramaId: 'o-1', fdiCode: fdi, superficies: const []);

/// Monta el odontodiagrama en un viewport lo bastante ancho para que el
/// diagrama quepa sin desplazamiento horizontal y se pueda tocar.
///
/// Con [conPiezas] el diagrama recibe las piezas normalizadas y abre panel al
/// tocar; sin ellas se comporta como la hoja del expediente y la impresión.
Future<RegistroDiagrama> montar(
  WidgetTester tester, {
  EvaluacionOdontologica inicial = EvaluacionOdontologica.vacia,
  bool editable = true,
  bool modoImpresion = false,
  bool conPiezas = true,
  List<EntradaLeyendaOdontograma>? leyenda,
  Size viewport = const Size(1200, 2400),
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final registro = RegistroDiagrama(inicial);
  final dientes = conPiezas
      ? {for (final fdi in kFdiTodas) fdi: _pieza(fdi)}
      : const <int, Diente>{};

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: OdontodiagramaWidget(
              evaluacion: registro.evaluacion,
              editable: editable,
              modoImpresion: modoImpresion,
              leyenda: leyenda,
              dientes: dientes,
              onChanged: (nueva) => setState(() => registro.evaluacion = nueva),
              onAddDiagnosis: (diente, superficie) =>
                  registro.diagnostico = PeticionPieza(diente, superficie),
              onAddTratamiento: (diente, superficie) =>
                  registro.tratamiento = PeticionPieza(diente, superficie),
              onToggleAusente: (diente, ausente) =>
                  registro.ausencia = (diente, ausente),
            ),
          ),
        ),
      ),
    ),
  );

  return registro;
}

void main() {
  group('EvaluacionOdontologica', () {
    test('una clave por superficie se acumula cara a cara', () {
      var evaluacion = EvaluacionOdontologica.vacia
          .alternar(
            16,
            EstadoClinicoDental.cariada,
            superficie: TipoSuperficie.oclusal,
          )
          .alternar(
            16,
            EstadoClinicoDental.cariada,
            superficie: TipoSuperficie.mesial,
          );

      expect(evaluacion.de(16).single.superficies, {
        TipoSuperficie.oclusal,
        TipoSuperficie.mesial,
      });

      // Volver a tocar la misma cara la retira sin perder las demás.
      evaluacion = evaluacion.alternar(
        16,
        EstadoClinicoDental.cariada,
        superficie: TipoSuperficie.oclusal,
      );
      expect(evaluacion.de(16).single.superficies, {TipoSuperficie.mesial});

      // Al quitar la última cara desaparece el hallazgo y con él la pieza.
      evaluacion = evaluacion.alternar(
        16,
        EstadoClinicoDental.cariada,
        superficie: TipoSuperficie.mesial,
      );
      expect(evaluacion.de(16), isEmpty);
      expect(evaluacion.hallazgos.containsKey(16), isFalse);
    });

    test('una clave de pieza completa se pone y se quita entera', () {
      final marcada = EvaluacionOdontologica.vacia.alternar(
        48,
        EstadoClinicoDental.perdida,
        superficie: TipoSuperficie.oclusal,
      );
      expect(marcada.de(48).single.esPiezaCompleta, isTrue);

      final limpia = marcada.alternar(48, EstadoClinicoDental.perdida);
      expect(limpia.de(48), isEmpty);
    });

    test('conviven varias claves sobre la misma pieza', () {
      final evaluacion = EvaluacionOdontologica.vacia
          .alternar(
            26,
            EstadoClinicoDental.cariada,
            superficie: TipoSuperficie.distal,
          )
          .alternar(
            26,
            EstadoClinicoDental.restaurada,
            superficie: TipoSuperficie.vestibular,
          )
          .alternar(26, EstadoClinicoDental.extraccionIndicada);

      expect(evaluacion.de(26).length, 3);
      expect(evaluacion.totalHallazgos, 3);
    });

    test('el JSON sobrevive al viaje por odontogramas.evaluacion_clinica', () {
      final original = EvaluacionOdontologica.vacia
          .alternar(
            16,
            EstadoClinicoDental.cariada,
            superficie: TipoSuperficie.oclusal,
          )
          .alternar(51, EstadoClinicoDental.noErupcionado)
          .conTejido(TejidoBlando.lengua, 'Lesión lateral izquierda')
          .conTejido(TejidoBlando.encias, '   ');

      final recuperada = OdontogramaModel.fromJson({
        'consulta_id': 'consulta-1',
        'evaluacion_clinica': original.toJson(),
      }).evaluacion;

      expect(recuperada.de(16).single.estado, EstadoClinicoDental.cariada);
      expect(recuperada.de(16).single.superficies, {TipoSuperficie.oclusal});
      expect(
        recuperada.de(51).single.estado,
        EstadoClinicoDental.noErupcionado,
      );
      expect(recuperada.de(51).single.esPiezaCompleta, isTrue);
      expect(
        recuperada.tejidosBlandos[TejidoBlando.lengua],
        'Lesión lateral izquierda',
      );
      // Una anotación en blanco no se guarda.
      expect(
        recuperada.tejidosBlandos.containsKey(TejidoBlando.encias),
        isFalse,
      );
    });

    test('un evaluacion_clinica ausente o corrupto no rompe el mapeo', () {
      expect(EvaluacionOdontologica.fromJson(null).estaVacia, isTrue);
      expect(EvaluacionOdontologica.fromJson('nada').estaVacia, isTrue);
      expect(
        EvaluacionOdontologica.fromJson({
          'hallazgos': {'no-es-fdi': 'basura', '16': 'tampoco'},
          'tejidos_blandos': {'inventado': 'x'},
        }).estaVacia,
        isTrue,
      );
    });
  });

  group('OdontodiagramaWidget', () {
    testWidgets('dibuja las dos denticiones a la vez, como el papel', (
      tester,
    ) async {
      await montar(tester, editable: false);

      // Permanentes de los cuatro cuadrantes.
      for (final fdi in [18, 11, 21, 28, 31, 38, 41, 48]) {
        expect(
          find.byKey(ValueKey('pieza_$fdi')),
          findsOneWidget,
          reason: 'falta la permanente $fdi',
        );
      }
      // Temporales de los cuatro cuadrantes, sin ningún selector de dentición.
      for (final fdi in [55, 51, 61, 65, 71, 75, 81, 85]) {
        expect(
          find.byKey(ValueKey('pieza_$fdi')),
          findsOneWidget,
          reason: 'falta la temporal $fdi',
        );
      }
      expect(find.text('Permanente'), findsNothing);
      expect(find.text('Temporal'), findsNothing);

      expect(find.text('Cuadrante 1'), findsOneWidget);
      expect(find.text('Cuadrante 2'), findsOneWidget);
      expect(find.text('Cuadrante 3'), findsOneWidget);
      expect(find.text('Cuadrante 4'), findsOneWidget);
    });

    testWidgets('tocar una pieza abre su panel, y volver a tocarla lo cierra', (
      tester,
    ) async {
      await montar(tester);

      expect(find.byType(PanelDetallePieza), findsNothing);

      await tester.tap(find.byKey(const ValueKey('pieza_16')));
      await tester.pumpAndSettle();

      expect(find.byType(PanelDetallePieza), findsOneWidget);
      expect(find.text(kFdiNames[16]!), findsOneWidget);
      // Los mismos dos botones que ofrece la arcada.
      expect(find.text('Diagnóstico'), findsOneWidget);
      expect(find.text('Tratamiento'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('pieza_16')));
      await tester.pumpAndSettle();
      expect(find.byType(PanelDetallePieza), findsNothing);
    });

    testWidgets('la cara se elige en el mapa del panel y viaja con la pieza', (
      tester,
    ) async {
      final registro = await montar(tester);

      await tester.tap(find.byKey(const ValueKey('pieza_16')));
      await tester.pumpAndSettle();

      // El centro del mapa es la cara oclusal en un posterior.
      final mapa = find.byKey(const ValueKey('mapa_superficies'));
      await tester.tapAt(tester.getCenter(mapa));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tratamiento'));
      await tester.pumpAndSettle();

      expect(registro.tratamiento!.diente.fdiCode, 16);
      expect(registro.tratamiento!.superficie, TipoSuperficie.oclusal);

      // Sin cara marcada, el diagnóstico sale de la pieza entera.
      await tester.tapAt(tester.getCenter(mapa));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Diagnóstico'));
      await tester.pumpAndSettle();

      expect(registro.diagnostico!.diente.fdiCode, 16);
      expect(registro.diagnostico!.superficie, isNull);
    });

    testWidgets('el panel de una temporal ofrece lo mismo que el de una '
        'permanente', (tester) async {
      final registro = await montar(tester);

      await tester.tap(find.byKey(const ValueKey('pieza_74')));
      await tester.pumpAndSettle();

      final mapa = find.byKey(const ValueKey('mapa_superficies'));
      await tester.tapAt(tester.getCenter(mapa));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tratamiento'));
      await tester.pumpAndSettle();

      expect(registro.tratamiento!.diente.fdiCode, 74);
      expect(registro.tratamiento!.superficie, TipoSuperficie.oclusal);
    });

    testWidgets('marcar la pieza como ausente se pide desde el panel', (
      tester,
    ) async {
      final registro = await montar(tester);

      await tester.tap(find.byKey(const ValueKey('pieza_36')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ausente'));
      await tester.pumpAndSettle();

      expect(registro.ausencia!.$1.fdiCode, 36);
      expect(registro.ausencia!.$2, isTrue);
    });

    testWidgets('el panel se abre del lado de su propia pieza', (tester) async {
      await montar(tester, viewport: const Size(1400, 2400));

      // La 16 es del hemicampo izquierdo de la hoja: su panel va a la
      // izquierda para no obligar a cruzar la vista.
      await tester.tap(find.byKey(const ValueKey('pieza_16')));
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.byType(PanelDetallePieza)).dx,
        lessThan(tester.getCenter(find.byKey(const ValueKey('pieza_16'))).dx),
      );

      await tester.tap(find.byKey(const ValueKey('pieza_26')));
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.byType(PanelDetallePieza)).dx,
        greaterThan(
          tester.getCenter(find.byKey(const ValueKey('pieza_26'))).dx,
        ),
      );
    });

    testWidgets('en un viewport estrecho el panel cae debajo sin desbordar', (
      tester,
    ) async {
      await montar(tester, viewport: const Size(600, 2400));

      await tester.tap(find.byKey(const ValueKey('pieza_16')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getCenter(find.byType(PanelDetallePieza)).dy,
        greaterThan(
          tester.getCenter(find.byKey(const ValueKey('pieza_16'))).dy,
        ),
      );
    });

    testWidgets('sin piezas normalizadas el diagrama no abre panel', (
      tester,
    ) async {
      await montar(tester, conPiezas: false);

      await tester.tap(find.byKey(const ValueKey('pieza_16')));
      await tester.pumpAndSettle();

      expect(find.byType(PanelDetallePieza), findsNothing);
    });

    testWidgets('los tejidos blandos se anotan en su tabla', (tester) async {
      final registro = await montar(tester);

      expect(find.text('Tejidos Blandos'), findsOneWidget);
      for (final tejido in TejidoBlando.values) {
        expect(find.text(tejido.label), findsOneWidget);
      }

      await tester.enterText(
        find.byKey(const ValueKey('tejido_lengua')),
        'Úlcera en borde lateral',
      );
      await tester.pump();

      expect(
        registro.evaluacion.tejidosBlandos[TejidoBlando.lengua],
        'Úlcera en borde lateral',
      );
    });

    testWidgets('la leyenda es configurable', (tester) async {
      await montar(
        tester,
        leyenda: [
          const EntradaLeyendaOdontograma(
            estado: EstadoClinicoDental.otro,
            tinta: kTintaNegra,
            marca: MarcaClinica.asterisco,
            etiqueta: 'Control ortodóncico',
          ),
        ],
      );

      expect(find.text('Control ortodóncico'), findsWidgets);
      expect(find.text('Cariada'), findsNothing);
    });

    testWidgets('el modo impresión quita los controles y deja las claves', (
      tester,
    ) async {
      await montar(tester, modoImpresion: true);

      // Sin paleta de claves ni campos de texto: es una hoja, no un formulario.
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('CLAVES'), findsOneWidget);
      expect(find.text('Cariada'), findsOneWidget);
      expect(find.byKey(const ValueKey('pieza_18')), findsOneWidget);
    });

    testWidgets('en modo lectura los tejidos se muestran como texto', (
      tester,
    ) async {
      await montar(
        tester,
        editable: false,
        inicial: EvaluacionOdontologica.vacia.conTejido(
          TejidoBlando.paladarDuro,
          'Torus palatino',
        ),
      );

      expect(find.text('Torus palatino'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('no desborda en 320 px', (tester) async {
      await montar(tester, viewport: const Size(320, 2400));

      expect(tester.takeException(), isNull);
      // El diagrama se desplaza en horizontal en lugar de comprimirse.
      expect(find.byKey(const ValueKey('pieza_18')), findsOneWidget);
      expect(find.text('CLAVES'), findsOneWidget);
    });
  });
}
