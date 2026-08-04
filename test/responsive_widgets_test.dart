import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';

/// Viewports every critical flow has to survive.
final _anchos = <double, AppLayout>{
  320: AppLayout.narrowMobile,
  360: AppLayout.mobile,
  390: AppLayout.mobile,
  768: AppLayout.tablet,
  1280: AppLayout.desktop,
};

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: inner!,
  ),
  home: child,
);

/// Opens [dialogo] and returns once it is on screen.
Future<void> _abrir(WidgetTester tester, Widget dialogo) async {
  await tester.pumpWidget(
    _app(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showDialog<void>(context: context, builder: (_) => dialogo),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void _viewport(WidgetTester tester, double ancho, [double alto = 800]) {
  tester.view.physicalSize = Size(ancho, alto);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('AppLayout', () {
    for (final entry in _anchos.entries) {
      test('resuelve ${entry.key.toInt()} px como ${entry.value.name}', () {
        expect(
          AppLayoutResolution.of(MediaQueryData(size: Size(entry.key, 800))),
          entry.value,
        );
      });
    }

    test(
      'el teclado abierto degrada a compacto aunque el ancho sea grande',
      () {
        final layout = AppLayoutResolution.of(
          const MediaQueryData(
            size: Size(1280, 800),
            viewInsets: EdgeInsets.only(bottom: 320),
          ),
        );
        expect(layout.isCompact, isTrue);
      },
    );

    test('el apaisado de un teléfono no se trata como escritorio', () {
      final layout = AppLayoutResolution.of(
        const MediaQueryData(size: Size(800, 390)),
      );
      expect(layout.isCompact, isTrue);
    });

    test('ofWidth permite resolver dentro de un LayoutBuilder', () {
      expect(AppLayoutResolution.ofWidth(320), AppLayout.narrowMobile);
      expect(AppLayoutResolution.ofWidth(500), AppLayout.mobile);
      expect(AppLayoutResolution.ofWidth(900), AppLayout.tablet);
      expect(AppLayoutResolution.ofWidth(1440), AppLayout.desktop);
    });
  });

  group('AppDialog', () {
    for (final ancho in _anchos.keys) {
      testWidgets('cabe en el viewport de ${ancho.toInt()} px', (tester) async {
        _viewport(tester, ancho);

        await _abrir(
          tester,
          const AppDialog(
            title: Text('Configurar plan'),
            preferredWidth: 510,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(decoration: InputDecoration(labelText: 'Cuotas')),
                SizedBox(height: 400),
                Text('Fin del contenido'),
              ],
            ),
            actions: [Text('Cancelar'), Text('Confirmar 12 cuotas')],
          ),
        );

        final superficie = tester.getRect(
          find
              .descendant(
                of: find.byType(Dialog),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(
          superficie.width,
          lessThanOrEqualTo(ancho),
          reason: 'el diálogo se sale de la pantalla',
        );
        expect(superficie.left, greaterThanOrEqualTo(0));
        expect(superficie.right, lessThanOrEqualTo(ancho));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('respeta el ancho preferido cuando la pantalla lo permite', (
      tester,
    ) async {
      _viewport(tester, 1280);
      await _abrir(
        tester,
        const AppDialog(preferredWidth: 510, content: Text('contenido')),
      );

      expect(tester.getSize(find.byKey(AppDialog.contentKey)).width, 510);
    });

    testWidgets('el contenido largo hace scroll en vez de desbordar', (
      tester,
    ) async {
      _viewport(tester, 360, 640);
      await _abrir(
        tester,
        AppDialog(
          title: const Text('Agregar condición'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 30; i++)
                const ListTile(title: Text('Condición')),
            ],
          ),
          actions: const [Text('Cancelar')],
        ),
      );

      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sobrevive al teclado abierto en 320 px', (tester) async {
      _viewport(tester, 320, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);

      await _abrir(
        tester,
        const AppDialog(
          title: Text('Nueva condición'),
          content: TextField(decoration: InputDecoration(labelText: 'Nombre')),
          actions: [Text('Cancelar'), Text('Crear y agregar')],
        ),
      );

      expect(tester.takeException(), isNull);
      // 320 - 2*16 de inset - 48 de padding interno.
      expect(tester.getSize(find.byKey(AppDialog.contentKey)).width, 240);
    });

    testWidgets('con texto ampliado no desborda en 320 px', (tester) async {
      _viewport(tester, 320, 800);
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: AppDialog(
              title: Text('Eliminar Consulta'),
              content: Text(
                'Esta consulta será eliminada junto con su odontograma, '
                'dientes, superficies y diagnósticos aplicados.',
              ),
              actions: [Text('Cancelar'), Text('Eliminar')],
            ),
          ),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('AppFormRow', () {
    Future<Rect> _campo(WidgetTester tester, String label) async =>
        tester.getRect(find.widgetWithText(TextField, label));

    testWidgets('apila los campos en móvil', (tester) async {
      _viewport(tester, 360);
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: AppFormRow(
              children: [
                TextField(decoration: InputDecoration(labelText: 'Cuotas')),
                TextField(decoration: InputDecoration(labelText: 'Frecuencia')),
              ],
            ),
          ),
        ),
      );

      final primero = await _campo(tester, 'Cuotas');
      final segundo = await _campo(tester, 'Frecuencia');
      expect(
        segundo.top,
        greaterThan(primero.bottom - 1),
        reason: 'los campos deben quedar uno debajo del otro',
      );
      expect(primero.width, segundo.width);
    });

    testWidgets('los pone lado a lado en escritorio', (tester) async {
      _viewport(tester, 1280);
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: AppFormRow(
              children: [
                TextField(decoration: InputDecoration(labelText: 'Cuotas')),
                TextField(decoration: InputDecoration(labelText: 'Frecuencia')),
              ],
            ),
          ),
        ),
      );

      final primero = await _campo(tester, 'Cuotas');
      final segundo = await _campo(tester, 'Frecuencia');
      expect(primero.top, segundo.top);
      expect(segundo.left, greaterThan(primero.right));
    });

    testWidgets('apila cuando cada campo quedaría demasiado estrecho', (
      tester,
    ) async {
      // Ancho de escritorio, pero el subárbol solo dispone de 300 px.
      _viewport(tester, 1280);
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: SizedBox(
              width: 300,
              child: AppFormRow(
                children: [
                  TextField(decoration: InputDecoration(labelText: 'Cuotas')),
                  TextField(
                    decoration: InputDecoration(labelText: 'Frecuencia'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final primero = await _campo(tester, 'Cuotas');
      final segundo = await _campo(tester, 'Frecuencia');
      expect(segundo.top, greaterThan(primero.bottom - 1));
    });
  });
}
