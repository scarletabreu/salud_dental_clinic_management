import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/paleta_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/vistas_odontograma.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Luminancia relativa (WCAG), para comprobar contraste sin depender de un
/// color concreto: lo que importa es que la tinta se separe del papel.
double _luminancia(Color c) {
  double canal(double v) => v <= 0.03928
      ? v / 12.92
      : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
}

double _contraste(Color a, Color b) {
  final la = _luminancia(a);
  final lb = _luminancia(b);
  final claro = la > lb ? la : lb;
  final oscuro = la > lb ? lb : la;
  return (claro + 0.05) / (oscuro + 0.05);
}

Future<void> _montar(
  WidgetTester tester, {
  required ThemeData tema,
  EvaluacionOdontologica evaluacion = EvaluacionOdontologica.vacia,
  EvaluacionOdontologica historico = EvaluacionOdontologica.vacia,
  bool editable = true,
  Size viewport = const Size(1400, 2600),
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: tema,
      home: Scaffold(
        body: SingleChildScrollView(
          child: OdontodiagramaWidget(
            evaluacion: evaluacion,
            historico: historico,
            editable: editable,
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('PaletaOdontodiagrama', () {
    test('cada tinta se separa de su papel en ambos temas', () {
      for (final paleta in [
        PaletaOdontodiagrama.claro,
        PaletaOdontodiagrama.oscuro,
      ]) {
        for (final estado in EstadoClinicoDental.values) {
          final tinta = paleta.tintaDe(estado);
          expect(
            _contraste(tinta, paleta.papel),
            greaterThan(3.0),
            reason:
                '${estado.label} no se lee sobre el papel '
                '${paleta.esOscura ? "oscuro" : "claro"}',
          );
        }
        expect(
          _contraste(paleta.trazo, paleta.papel),
          greaterThan(3.0),
          reason: 'el trazo del glifo no se separa del papel',
        );
        expect(
          _contraste(paleta.textoFuerte, paleta.papel),
          greaterThan(4.5),
          reason: 'el texto de la tabla no se lee sobre el papel',
        );
      }
    });

    test('la roja sigue siendo roja y la azul azul en modo oscuro', () {
      // El dato clínico es el rol de la tinta, no su valor RGB: si la
      // «restaurada» dejara de tener el canal azul dominante, el doctor
      // perdería la convención del papel.
      final roja = PaletaOdontodiagrama.oscuro.tintaDe(
        EstadoClinicoDental.cariada,
      );
      final azul = PaletaOdontodiagrama.oscuro.tintaDe(
        EstadoClinicoDental.restaurada,
      );
      expect(roja.r, greaterThan(roja.b));
      expect(azul.b, greaterThan(azul.r));
    });

    test('la hoja imprimible no depende del tema', () {
      expect(
        PaletaOdontodiagrama.impresion.tintaDe(EstadoClinicoDental.cariada),
        kTintaRoja,
      );
      expect(PaletaOdontodiagrama.impresion.papel, const Color(0xFFFDFDFC));
      expect(PaletaOdontodiagrama.impresion.esOscura, isFalse);
    });
  });

  group('OdontodiagramaWidget y el tema', () {
    testWidgets('en modo oscuro el papel deja de ser blanco', (tester) async {
      await _montar(tester, tema: AppTheme.dark);

      final panel = tester.widget<Container>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('pieza_18')),
              matching: find.byType(Container),
            )
            .last,
      );
      final color = (panel.decoration as BoxDecoration).color;
      expect(color, PaletaOdontodiagrama.oscuro.papel);
      expect(color, isNot(PaletaOdontodiagrama.impresion.papel));
    });

    testWidgets('en modo claro conserva el papel del formulario', (
      tester,
    ) async {
      await _montar(tester, tema: AppTheme.light);

      final panel = tester.widget<Container>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('pieza_18')),
              matching: find.byType(Container),
            )
            .last,
      );
      expect(
        (panel.decoration as BoxDecoration).color,
        PaletaOdontodiagrama.impresion.papel,
      );
    });

    testWidgets('la hoja de expediente ignora el tema oscuro', (tester) async {
      tester.view.physicalSize = const Size(1400, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: OdontodiagramaPapel(
                evaluacion: EvaluacionOdontologica.vacia,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final hoja = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(OdontodiagramaWidget),
              matching: find.byType(Container),
            )
            .last,
      );
      expect(hoja.color, PaletaOdontodiagrama.impresion.papel);
    });
  });

  group('Objetivos táctiles', () {
    testWidgets('una pieza anotable no baja de 40 px ni en un viewport corto', (
      tester,
    ) async {
      // 500 px no dan para 16 columnas de 44: el diagrama se desplaza en
      // horizontal en vez de comprimir las piezas por debajo del dedo.
      await _montar(
        tester,
        tema: AppTheme.light,
        viewport: const Size(500, 2600),
      );

      final tamano = tester.getSize(find.byKey(const ValueKey('pieza_16')));
      expect(tamano.width, greaterThanOrEqualTo(40));
      expect(tamano.height, greaterThanOrEqualTo(40));
    });

    testWidgets('en solo lectura sí puede comprimirse para caber entero', (
      tester,
    ) async {
      await _montar(
        tester,
        tema: AppTheme.light,
        editable: false,
        viewport: const Size(500, 2600),
      );

      // La pieza no es un objetivo: prima que la boca se lea de un vistazo.
      final tamano = tester.getSize(find.byKey(const ValueKey('pieza_16')));
      expect(tamano.width, lessThan(40));
    });

    testWidgets('cada chip de clave llega al objetivo táctil de Material', (
      tester,
    ) async {
      await _montar(tester, tema: AppTheme.light);

      for (final clave in ['clave_cariada', 'clave_perdida', 'clave_ficha']) {
        final alto = tester.getSize(find.byKey(ValueKey(clave))).height;
        expect(
          alto,
          greaterThanOrEqualTo(44),
          reason: '$clave es demasiado pequeño para el dedo',
        );
      }
    });

    testWidgets('el modo ficha abre la pieza con un toque simple', (
      tester,
    ) async {
      await _montar(tester, tema: AppTheme.light);

      await tester.tap(find.byKey(const ValueKey('clave_ficha')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('pieza_16')));
      await tester.pumpAndSettle();

      expect(find.text('Pieza 16'), findsOneWidget);
    });

    testWidgets('el selector de vistas mide al menos 44 px de alto', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SelectorVistaOdontograma(
              vista: VistaOdontograma.formulario,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(SelectorVistaOdontograma)).height,
        greaterThanOrEqualTo(44),
      );
    });
  });

  group('Capa histórica', () {
    testWidgets('lo anotado antes se anuncia y llega a la ficha', (
      tester,
    ) async {
      await _montar(
        tester,
        tema: AppTheme.light,
        historico: EvaluacionOdontologica.vacia.alternar(
          16,
          EstadoClinicoDental.restaurada,
          superficie: TipoSuperficie.oclusal,
        ),
      );

      expect(
        find.text('El trazo tenue viene de consultas anteriores.'),
        findsOneWidget,
      );

      await tester.longPress(find.byKey(const ValueKey('pieza_16')));
      await tester.pumpAndSettle();

      expect(find.text('DE CONSULTAS ANTERIORES'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('historico_restaurada')),
        findsOneWidget,
      );
      // Es de solo lectura: no aparece como hallazgo editable de hoy.
      expect(find.byKey(const ValueKey('hallazgo_restaurada')), findsNothing);
    });

    testWidgets('sin histórico no se anuncia nada', (tester) async {
      await _montar(tester, tema: AppTheme.light);

      expect(
        find.text('El trazo tenue viene de consultas anteriores.'),
        findsNothing,
      );
    });

    testWidgets('una clave repetida hoy no se dibuja además en tenue', (
      tester,
    ) async {
      final marca = EvaluacionOdontologica.vacia.alternar(
        36,
        EstadoClinicoDental.perdida,
      );
      await _montar(
        tester,
        tema: AppTheme.light,
        evaluacion: marca,
        historico: marca,
      );

      await tester.longPress(find.byKey(const ValueKey('pieza_36')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('hallazgo_perdida')), findsOneWidget);
      // La ficha sigue mostrando el antecedente, pero el glifo no lo duplica:
      // eso lo garantiza `menos`, verificado aparte.
      expect(marca.menos(marca).estaVacia, isTrue);
    });

    testWidgets('el tejido blando anterior se ofrece como referencia', (
      tester,
    ) async {
      await _montar(
        tester,
        tema: AppTheme.light,
        historico: EvaluacionOdontologica.vacia.conTejido(
          TejidoBlando.lengua,
          'Úlcera en borde lateral',
        ),
      );

      final campo = tester.widget<TextField>(
        find.byKey(const ValueKey('tejido_lengua')),
      );
      expect(campo.decoration!.hintText, 'Úlcera en borde lateral');
    });
  });

  group('EvaluacionOdontologica.consolidar', () {
    test('gana la anotación más reciente de cada pieza', () {
      final reciente = EvaluacionOdontologica.vacia
          .alternar(16, EstadoClinicoDental.restaurada)
          .conTejido(TejidoBlando.lengua, 'Sin alteración');
      final antigua = EvaluacionOdontologica.vacia
          .alternar(16, EstadoClinicoDental.cariada)
          .alternar(26, EstadoClinicoDental.perdida)
          .conTejido(TejidoBlando.lengua, 'Úlcera');

      // De la más reciente a la más antigua, como llega el historial.
      final total = EvaluacionOdontologica.consolidar([reciente, antigua]);

      expect(total.de(16).single.estado, EstadoClinicoDental.restaurada);
      expect(total.de(26).single.estado, EstadoClinicoDental.perdida);
      expect(total.tejidosBlandos[TejidoBlando.lengua], 'Sin alteración');
    });

    test('una lista vacía da una evaluación vacía', () {
      expect(EvaluacionOdontologica.consolidar(const []).estaVacia, isTrue);
    });
  });

  group('EvaluacionOdontologica.menos', () {
    test('descuenta solo las claves que ya están anotadas hoy', () {
      final historico = EvaluacionOdontologica.vacia
          .alternar(16, EstadoClinicoDental.cariada)
          .alternar(16, EstadoClinicoDental.restaurada)
          .alternar(26, EstadoClinicoDental.perdida);
      final hoy = EvaluacionOdontologica.vacia.alternar(
        16,
        EstadoClinicoDental.cariada,
      );

      final tenue = historico.menos(hoy);

      expect(tenue.de(16).single.estado, EstadoClinicoDental.restaurada);
      expect(tenue.de(26).single.estado, EstadoClinicoDental.perdida);
    });

    test('un tejido con el mismo texto no se repite en tenue', () {
      final historico = EvaluacionOdontologica.vacia
          .conTejido(TejidoBlando.lengua, 'Úlcera')
          .conTejido(TejidoBlando.encias, 'Gingivitis');
      final hoy = EvaluacionOdontologica.vacia.conTejido(
        TejidoBlando.lengua,
        'Úlcera',
      );

      final tenue = historico.menos(hoy);

      expect(tenue.tejidosBlandos.containsKey(TejidoBlando.lengua), isFalse);
      expect(tenue.tejidosBlandos[TejidoBlando.encias], 'Gingivitis');
    });
  });
}
