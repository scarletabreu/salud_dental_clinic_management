import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/pages/mis_citas_del_dia_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

/// SD-161. Los tres estados de la agenda tienen que ser distinguibles: antes,
/// un fallo de carga se pintaba como una agenda llena de citas inventadas y
/// una base vacía era indistinguible de un día sin citas.
class _CitaCubitDoble extends Cubit<CitaCubitState> implements CitaCubit {
  _CitaCubitDoble(super.initialState);

  int recargas = 0;

  @override
  Future<void> load() async => recargas++;

  @override
  List<Cita> eventLoader(DateTime day) {
    final actual = state;
    return actual is CitaCubitLoaded ? actual.citasForDay(day) : const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final _hoy = DateTime(2026, 7, 22);

Doctor _doctor() => Doctor(
  id: '22222222-2222-2222-2222-222222222222',
  nombre: 'Bartolomé',
  apellido: 'Santana Villalona',
  birthDate: DateTime(1985, 3, 2),
  govID: '402-1234567-1',
  contactos: const [],
  estatus: EstatusPersona.activo,
  username: 'bsantana',
  passwordHash: 'x',
  specialty: 'Endodoncia',
  assistants: const [],
);

Paciente _paciente() => Paciente(
  id: '11111111-1111-1111-1111-111111111111',
  nombre: 'Ana Mercedes',
  apellido: 'Rodríguez Montás',
  birthDate: DateTime(1990, 5, 12),
  govID: '001-1234567-8',
  contactos: [
    Contacto(
      numeroTelefono: '809-555-0134',
      email: 'paciente@correo.com.do',
      direccion: 'Santo Domingo',
    ),
  ],
  estatus: EstatusPersona.activo,
  genero: Genero.femenino,
  trabajo: 'Docente',
  referencia: '—',
  citas: const [],
  tipoPaciente: TipoPaciente.integrado,
  record: Record(
    pacienteId: '11111111-1111-1111-1111-111111111111',
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const [],
    historialFamiliar: '',
  ),
);

CitaCubitLoaded _cargada({required List<Cita> citas}) => CitaCubitLoaded(
  citas: citas,
  focusedDay: _hoy,
  selectedDay: _hoy,
  viewMode: CalendarioViewMode.mensual,
);

Cita _cita() => Cita(
  id: '33333333-3333-3333-3333-333333333333',
  doctor: _doctor(),
  persona: _paciente(),
  date: DateTime(2026, 7, 22, 9, 30),
  duracionMinutos: 45,
  esEmergencia: false,
  estado: EstadoCita.confirmada,
);

Widget _app(_CitaCubitDoble cubit) => MaterialApp(
  theme: AppTheme.light,
  home: BlocProvider<CitaCubit>.value(
    value: cubit,
    child: const MisCitasDelDiaPage(),
  ),
);

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('cargando muestra el indicador y ninguna cita', (tester) async {
    _viewport(tester);
    final cubit = _CitaCubitDoble(const CitaCubitLoading());
    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Aún no hay citas registradas'), findsNothing);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('error muestra el mensaje y un botón de reintento', (
    tester,
  ) async {
    _viewport(tester);
    final cubit = _CitaCubitDoble(
      const CitaCubitError('Error al obtener las citas: permiso denegado'),
    );
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Error al cargar citas'), findsOneWidget);
    expect(
      find.text('Error al obtener las citas: permiso denegado'),
      findsOneWidget,
    );
    // El fallo no se disfraza de agenda: no hay ninguna cita en pantalla.
    expect(find.text('Aún no hay citas registradas'), findsNothing);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(cubit.recargas, 1);
  });

  testWidgets('agenda vacía se explica y ofrece actualizar', (tester) async {
    _viewport(tester);
    final cubit = _CitaCubitDoble(_cargada(citas: const []));
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay citas registradas'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Error al cargar citas'), findsNothing);

    await tester.tap(find.text('Actualizar'));
    await tester.pump();
    expect(cubit.recargas, 1);
  });

  testWidgets('con citas reales no se muestra el aviso de agenda vacía', (
    tester,
  ) async {
    _viewport(tester);
    final cubit = _CitaCubitDoble(_cargada(citas: [_cita()]));
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay citas registradas'), findsNothing);
    expect(find.text('Error al cargar citas'), findsNothing);
    expect(find.textContaining('Rodríguez Montás'), findsWidgets);
  });

  testWidgets('el aviso de agenda vacía no desborda en 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = _CitaCubitDoble(_cargada(citas: const []));
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay citas registradas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
