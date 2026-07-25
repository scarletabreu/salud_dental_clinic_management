import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/models/odontograma_model.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Monta el odontodiagrama en un viewport lo bastante ancho para que el
/// diagrama quepa sin desplazamiento horizontal y se pueda tocar.
Future<EvaluacionOdontologica Function()> montar(
  WidgetTester tester, {
  EvaluacionOdontologica inicial = EvaluacionOdontologica.vacia,
  bool editable = true,
  bool modoImpresion = false,
  List<EntradaLeyendaOdontograma>? leyenda,
  Size viewport = const Size(1200, 2400),
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  var evaluacion = inicial;

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: OdontodiagramaWidget(
              evaluacion: evaluacion,
              editable: editable,
              modoImpresion: modoImpresion,
              leyenda: leyenda,
              onChanged: (nueva) => setState(() => evaluacion = nueva),
            ),
          ),
        ),
      ),
    ),
  );

  return () => evaluacion;
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

    testWidgets('tocar una pieza anota la cara señalada', (tester) async {
      final leer = await montar(tester);

      // La clave activa por defecto es la primera del formulario: Cariada.
      await tester.tap(find.byKey(const ValueKey('pieza_16')));
      await tester.pump();

      final hallazgo = leer().de(16).single;
      expect(hallazgo.estado, EstadoClinicoDental.cariada);
      // El centro de un posterior es la cara oclusal.
      expect(hallazgo.superficies, {TipoSuperficie.oclusal});

      // Un anterior tiene borde incisal en el centro.
      await tester.tap(find.byKey(const ValueKey('pieza_11')));
      await tester.pump();
      expect(leer().de(11).single.superficies, {TipoSuperficie.incisal});
    });

    testWidgets('una clave de pieza completa no pide cara', (tester) async {
      final leer = await montar(tester);

      await tester.tap(find.byKey(const ValueKey('clave_perdida')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('pieza_36')));
      await tester.pump();

      final hallazgo = leer().de(36).single;
      expect(hallazgo.estado, EstadoClinicoDental.perdida);
      expect(hallazgo.esPiezaCompleta, isTrue);

      // Vuelve a tocarla y se borra.
      await tester.tap(find.byKey(const ValueKey('pieza_36')));
      await tester.pump();
      expect(leer().de(36), isEmpty);
    });

    testWidgets('la ficha de la pieza permite detallar caras y quitar claves', (
      tester,
    ) async {
      final leer = await montar(
        tester,
        inicial: EvaluacionOdontologica.vacia.alternar(
          26,
          EstadoClinicoDental.perdida,
        ),
      );

      await tester.longPress(find.byKey(const ValueKey('pieza_26')));
      await tester.pumpAndSettle();

      expect(find.text('Pieza 26'), findsOneWidget);
      expect(find.byKey(const ValueKey('hallazgo_perdida')), findsOneWidget);

      // Añade una caries en dos caras concretas.
      await tester.tap(find.byKey(const ValueKey('cara_mesial')));
      await tester.tap(find.byKey(const ValueKey('cara_oclusal')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final hallazgos = leer().de(26);
      expect(hallazgos.length, 2);
      final caries = hallazgos.firstWhere(
        (h) => h.estado == EstadoClinicoDental.cariada,
      );
      expect(caries.superficies, {
        TipoSuperficie.mesial,
        TipoSuperficie.oclusal,
      });
    });

    testWidgets('los tejidos blandos se anotan en su tabla', (tester) async {
      final leer = await montar(tester);

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
        leer().tejidosBlandos[TejidoBlando.lengua],
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
