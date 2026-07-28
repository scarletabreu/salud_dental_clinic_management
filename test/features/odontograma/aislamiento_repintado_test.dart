import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/glifo_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';

/// Capa de repintado a la que pertenece [nodo]: el `RepaintBoundary` más
/// cercano subiendo por el árbol de render.
///
/// Dos piezas que devuelvan la *misma* capa se repintan juntas: tocar una
/// obliga a redibujar la otra.
RenderRepaintBoundary? _capaDe(RenderObject nodo) {
  RenderObject? actual = nodo.parent;
  while (actual != null) {
    if (actual is RenderRepaintBoundary) return actual;
    actual = actual.parent;
  }
  return null;
}

/// Todos los dibujos de pieza del odontodiagrama presentes en el árbol.
List<RenderCustomPaint> _piezas(WidgetTester tester) => tester
    .renderObjectList<RenderCustomPaint>(
      find.byType(CustomPaint, skipOffstage: false),
    )
    .where((r) => r.painter is GlifoPiezaPainter)
    .toList();

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Future<void> _montarDiagrama(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    _app(const OdontodiagramaWidget(evaluacion: EvaluacionOdontologica.vacia)),
  );
  await tester.pump();
}

void main() {
  group('Odontodiagrama · aislamiento de repintado (SD-132)', () {
    testWidgets('cada pieza repinta en una capa propia', (tester) async {
      await _montarDiagrama(tester);

      final piezas = _piezas(tester);
      expect(
        piezas.length,
        greaterThanOrEqualTo(28),
        reason: 'se esperaba la boca completa',
      );

      final capas = <RenderRepaintBoundary>{};
      for (final pieza in piezas) {
        final capa = _capaDe(pieza);
        expect(
          capa,
          isNotNull,
          reason: 'una pieza quedó sin frontera de repintado',
        );
        capas.add(capa!);
      }

      // Si las ${piezas.length} piezas comparten capa, resaltar un molar
      // redibuja la boca entera en cada frame del hover.
      expect(
        capas.length,
        piezas.length,
        reason:
            'hay piezas compartiendo capa de repintado: '
            '${piezas.length} piezas en ${capas.length} capas',
      );
    });

    testWidgets('el aislamiento no rompe la lectura accesible del diagrama', (
      tester,
    ) async {
      await _montarDiagrama(tester);

      expect(find.bySemanticsLabel(RegExp(r'Pieza \d+')), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
