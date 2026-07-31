import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/seleccionar_medicina_sheet.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/dientes_iniciales.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/panel_detalle_pieza.dart';

Medicina _medicina(String nombre) =>
    Medicina(id: nombre, nombre: nombre, contraindicaciones: const []);

Future<void> _montarDiagrama(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: OdontodiagramaWidget(
            evaluacion: EvaluacionOdontologica.vacia,
            editable: true,
            dientes: {
              for (final fdi in kFdiTodas)
                fdi: Diente(
                  odontogramaId: 'o-1',
                  fdiCode: fdi,
                  superficies: const [],
                ),
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('selector de medicinas', () {
    testWidgets('se abre sin la aserción de ListTile y lista el catálogo', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => seleccionarMedicina(context, [
                    _medicina('Amoxicilina'),
                    _medicina('Ibuprofeno'),
                  ]),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // El defecto auditado: el fondo de la hoja tapaba el Material sobre el
      // que las filas pintan su realce y el framework abortaba el frame, así
      // que el selector no llegaba a verse.
      expect(tester.takeException(), isNull);
      expect(find.text('Amoxicilina'), findsOneWidget);
      expect(find.text('Ibuprofeno'), findsOneWidget);
    });

    testWidgets('se puede elegir una medicina con el teclado', (tester) async {
      Medicina? elegida;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    elegida = await seleccionarMedicina(context, [
                      _medicina('Amoxicilina'),
                    ]);
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(elegida?.nombre, 'Amoxicilina');
    });
  });

  group('odontograma', () {
    testWidgets('cada pieza se anuncia con su número y sus hallazgos', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _montarDiagrama(tester);

      expect(find.bySemanticsLabel('Pieza 11, sin hallazgos'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('una pieza se abre con el teclado, no sólo con el ratón', (
      tester,
    ) async {
      await _montarDiagrama(tester);

      // Anotar un hallazgo empieza por abrir la pieza: si eso sólo se puede
      // con el ratón, el recorrido con teclado se corta aquí.
      var intentos = 0;
      while (find.byType(PanelDetallePieza).evaluate().isEmpty &&
          intentos < 40) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        intentos++;
      }

      expect(find.byType(PanelDetallePieza), findsOneWidget);
    });
  });

  group('diálogos altos', () {
    testWidgets('en un viewport muy alto el contenido no se estira sin freno', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AppDialog(
                    title: const Text('Formulario largo'),
                    content: Column(
                      children: [
                        for (var i = 0; i < 60; i++)
                          SizedBox(height: 40, child: Text('Campo $i')),
                      ],
                    ),
                    actions: const [Text('Aceptar')],
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final caja = tester.getSize(find.byKey(AppDialog.contentKey));
      expect(caja.height, lessThanOrEqualTo(620));
      expect(tester.takeException(), isNull);
    });
  });
}
