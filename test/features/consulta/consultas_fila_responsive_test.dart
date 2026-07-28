import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/consultas_list_page.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

const _doctorId = 'doctor-1';

class _AuthCubitDoble extends Cubit<AuthState> implements AuthCubit {
  _AuthCubitDoble(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

AuthState _sesionDe(String doctorId) => AuthState(
  isAuthenticated: true,
  usuario: Doctor(
    id: doctorId,
    nombre: 'Bartolomé',
    apellido: 'Santana',
    birthDate: DateTime(1985),
    govID: '001',
    contactos: const [],
    estatus: EstatusPersona.activo,
    username: 'bsantana',
    passwordHash: '',
    specialty: 'General',
    assistants: const [],
  ),
);

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

Consulta _consulta(
  String id, {
  required bool receta,
  bool finalizada = true,
}) => Consulta(
  id: id,
  pacienteId: 'paciente-$id',
  doctorId: _doctorId,
  fecha: DateTime.now().subtract(const Duration(days: 1)),
  finalizada: finalizada,
  recetas: receta
      ? [
          Receta(
            codigoReceta: 'RX-$id',
            consultaId: id,
            pacienteId: 'paciente-$id',
            doctorId: _doctorId,
            fechaEmision: DateTime(2026, 7, 27),
            items: const [
              ItemReceta(
                nombreMedicamento: 'Amoxicilina',
                presentacionConcentracion: '500 mg',
                dosis: '1 tableta',
                frecuencia: 'Cada 8 horas',
                duracion: '7 días',
                indicacionesEspecificas: 'Con alimentos',
              ),
            ],
          ),
        ]
      : const [],
);

Widget _app({AuthState? sesion}) => MaterialApp(
  theme: AppTheme.light,
  home: BlocProvider<AuthCubit>(
    create: (_) => _AuthCubitDoble(sesion ?? _sesionDe(_doctorId)),
    child: Scaffold(
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
  ),
);

/// Una sola fila en curso, para observar la acción principal bajo el permiso
/// por rol que introdujo SD-149.
Widget _appEnCurso({required String doctorEnSesion}) => MaterialApp(
  theme: AppTheme.light,
  home: BlocProvider<AuthCubit>(
    create: (_) => _AuthCubitDoble(_sesionDe(doctorEnSesion)),
    child: Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ConsultaListCard(
            consulta: _consulta(
              'en-curso',
              receta: false,
              finalizada: false,
            ),
            nombrePaciente: 'Ana Mercedes Rodríguez Montás',
            nombreDoctor: 'Bartolomé Santana Villalona',
            tieneTratamientos: false,
            onTap: () {},
          ),
        ],
      ),
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

  testWidgets('el doctor de la consulta puede continuarla', (tester) async {
    _viewport(tester, const Size(390, 900));
    await tester.pumpWidget(_appEnCurso(doctorEnSesion: _doctorId));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.navigate_next_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('otro doctor no puede continuar la consulta ajena', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 900));
    await tester.pumpWidget(_appEnCurso(doctorEnSesion: 'doctor-2'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.navigate_next_rounded), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(
      find.byKey(const ValueKey('consulta-accion-principal-en-curso')),
      findsOneWidget,
    );
  });
}
