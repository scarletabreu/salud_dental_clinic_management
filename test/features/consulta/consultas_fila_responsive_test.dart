import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/consultas_list_page.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

final _viewports = <String, Size>{
  '320 px': const Size(320, 900),
  '360 px': const Size(360, 900),
  '390 px': const Size(390, 900),
  'tablet': const Size(768, 1024),
  'escritorio': const Size(1280, 900),
};

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Consulta _consulta(String id, {required bool receta}) => Consulta(
  id: id,
  pacienteId: 'paciente-$id',
  doctorId: 'doctor-1',
  fecha: DateTime.now().subtract(const Duration(days: 1)),
  finalizada: true,
  recetas: receta
      ? [
          Receta(
            title: 'Amoxicilina',
            createdAt: DateTime(2026, 7, 27),
            medicinaId: 'med-1',
            dosis: '500 mg',
            frecuencia: 'Cada 8 horas',
            indicaciones: 'Con alimentos',
            duracion: '7 días',
          ),
        ]
      : const [],
);

Widget _app() => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ConsultaListCard(
          consulta: _consulta('sin-indicadores', receta: false),
          nombrePaciente: 'Ana Mercedes Rodríguez Montás',
          nombreDoctor: 'Bartolomé Santana Villalona',
          tieneTratamientos: false,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        ConsultaListCard(
          consulta: _consulta('un-indicador', receta: true),
          nombrePaciente: 'Ana Mercedes Rodríguez Montás',
          nombreDoctor: 'Bartolomé Santana Villalona',
          tieneTratamientos: false,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        ConsultaListCard(
          consulta: _consulta('dos-indicadores', receta: true),
          nombrePaciente: 'Ana Mercedes Rodríguez Montás',
          nombreDoctor: 'Bartolomé Santana Villalona',
          tieneTratamientos: true,
          onTap: () {},
        ),
      ],
    ),
  ),
);

void main() {
  for (final entry in _viewports.entries) {
    testWidgets(
      'la fila de consulta no desborda y alinea acciones en ${entry.key}',
      (tester) async {
        _viewport(tester, entry.value);
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final actions = ['sin-indicadores', 'un-indicador', 'dos-indicadores']
            .map(
              (id) => tester.getRect(
                find.byKey(ValueKey('consulta-accion-principal-$id')),
              ),
            );
        final rightEdges = actions.map((rect) => rect.right).toList();
        for (final rightEdge in rightEdges.skip(1)) {
          expect(rightEdge, closeTo(rightEdges.first, 0.01));
        }
      },
    );
  }

  testWidgets('el menú explica por qué no se puede eliminar la consulta', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 900));
    await tester.pumpWidget(_app());
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Eliminar consulta'), findsOneWidget);
    expect(
      find.text('Solo se pueden eliminar consultas creadas hoy.'),
      findsOneWidget,
    );
  });
}
