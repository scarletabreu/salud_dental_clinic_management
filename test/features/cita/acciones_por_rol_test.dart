import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/pages/mis_citas_del_dia_page.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

/// HFX-CLIN-004 · Qué puede hacer cada actor sobre una cita concreta.
///
/// El doctor que trabajaba sin recepción quedaba atrapado: nadie llevaba su
/// cita a «en espera», y sin ese estado «Iniciar consulta» no aparecía nunca.
/// El asistente, en cambio, no puede entrar a la consulta por mucho que gestione
/// la agenda. Tener más permisos no es poder firmar clínica, y poder marcar la
/// llegada no es poder atender.
void main() {
  testWidgets('el doctor registra la llegada de su propia cita', (
    tester,
  ) async {
    _viewport(tester);
    final cubit = _CitaCubitDoble(
      _cargada([_cita(estado: EstadoCita.confirmada)]),
    );
    await tester.pumpWidget(_app(cubit, usuario: _doctorPropio));
    await tester.pumpAndSettle();

    expect(find.text('Registrar llegada'), findsOneWidget);
    // Todavía no ha llegado: no se puede iniciar la consulta.
    expect(find.text('Iniciar consulta'), findsNothing);

    await tester.tap(find.text('Registrar llegada'));
    await tester.pump();
    expect(cubit.llegadasRegistradas, ['cita-1']);
  });

  testWidgets('con el paciente ya en espera el doctor entra a la consulta', (
    tester,
  ) async {
    _viewport(tester);
    final cubit = _CitaCubitDoble(
      _cargada([_cita(estado: EstadoCita.enEspera)]),
    );
    await tester.pumpWidget(_app(cubit, usuario: _doctorPropio));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar consulta'), findsOneWidget);
    expect(find.text('Registrar llegada'), findsNothing);
  });

  testWidgets('un doctor no toca la cita de otro doctor', (tester) async {
    _viewport(tester);
    final cubit = _CitaCubitDoble(
      _cargada([_cita(estado: EstadoCita.confirmada)]),
    );
    await tester.pumpWidget(_app(cubit, usuario: _otroDoctor));
    await tester.pumpAndSettle();

    expect(find.text('Registrar llegada'), findsNothing);
    expect(find.text('Iniciar consulta'), findsNothing);
  });

  testWidgets('el asistente marca la llegada pero no ejerce clínica', (
    tester,
  ) async {
    _viewport(tester);
    final cubit = _CitaCubitDoble(
      _cargada([_cita(estado: EstadoCita.enEspera)]),
    );
    await tester.pumpWidget(_app(cubit, usuario: _asistente));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar consulta'), findsNothing);
  });

  // Antes esta prueba fijaba que el doctor sólo tenía la vía de urgencia. QA
  // lo señaló como defecto (D10): degradar una cita normal a urgencia falsea
  // el motivo y salta el control de solapamiento. La base ya le permitía
  // insertar citas propias desde HFX-CLIN-001; ahora la pantalla también, con
  // el selector de odontólogo fijo en él.
  testWidgets('el doctor tiene ambas vías, y agenda sólo para sí mismo', (
    tester,
  ) async {
    _viewport(tester);
    final cubit = _CitaCubitDoble(_cargada(const []));
    await tester.pumpWidget(_app(cubit, usuario: _doctorPropio));
    await tester.pumpAndSettle();

    expect(
      find.byTooltip('Registrar urgencia (paciente sin cita)'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FloatingActionButton, 'Nueva Cita'),
      findsOneWidget,
    );
  });

  testWidgets('quien gestiona la agenda tiene ambas vías', (tester) async {
    _viewport(tester);
    final cubit = _CitaCubitDoble(_cargada(const []));
    await tester.pumpWidget(_app(cubit, usuario: _asistente));
    await tester.pumpAndSettle();

    expect(
      find.byTooltip('Registrar urgencia (paciente sin cita)'),
      findsOneWidget,
    );
    expect(find.text('Nueva Cita'), findsOneWidget);
  });
}

final _hoy = DateTime(2026, 7, 22);

final _doctorPropio = Doctor(
  id: 'doctor-1',
  nombre: 'Bartolomé',
  apellido: 'Santana',
  birthDate: DateTime(1985, 3, 2),
  govID: '402-1234567-1',
  contactos: const [],
  estatus: EstatusPersona.activo,
  username: 'bsantana',
  specialty: 'Endodoncia',
  assistants: const [],
);

final _otroDoctor = Doctor(
  id: 'doctor-2',
  nombre: 'Elena',
  apellido: 'Guzmán',
  birthDate: DateTime(1987, 6, 4),
  govID: '402-1234567-2',
  contactos: const [],
  estatus: EstatusPersona.activo,
  username: 'eguzman',
  specialty: 'General',
  assistants: const [],
);

final _asistente = Asistente(
  id: 'asistente-1',
  nombre: 'Carla',
  apellido: 'Recepción',
  birthDate: DateTime(1992, 1, 1),
  govID: '402-7654321-9',
  contactos: const [],
  estatus: EstatusPersona.activo,
  username: 'crecepcion',
  shift: 'matutino',
);

Cita _cita({required EstadoCita estado}) => Cita(
  id: 'cita-1',
  doctor: _doctorPropio,
  persona: Persona(
    id: 'paciente-1',
    nombre: 'Ana Mercedes',
    apellido: 'Rodríguez',
    birthDate: DateTime(1990, 5, 12),
    govID: '001-1234567-8',
    contactos: const [],
    estatus: EstatusPersona.activo,
  ),
  date: DateTime(2026, 7, 22, 9, 30),
  duracionMinutos: 45,
  esEmergencia: false,
  estado: estado,
);

CitaCubitLoaded _cargada(List<Cita> citas) => CitaCubitLoaded(
  citas: citas,
  focusedDay: _hoy,
  selectedDay: _hoy,
  viewMode: CalendarioViewMode.mensual,
);

class _CitaCubitDoble extends Cubit<CitaCubitState> implements CitaCubit {
  _CitaCubitDoble(super.initialState);

  final llegadasRegistradas = <String>[];

  @override
  Future<void> load({
    String? restringidoADoctorId,
    List<String>? doctorIdsPermitidos,
  }) async {}

  @override
  Future<void> registrarLlegada(String citaId) async {
    llegadasRegistradas.add(citaId);
  }

  @override
  List<Cita> eventLoader(DateTime day) {
    final actual = state;
    return actual is CitaCubitLoaded ? actual.citasForDay(day) : const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _AuthCubitDoble extends Cubit<AuthState> implements AuthCubit {
  _AuthCubitDoble(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Widget _app(_CitaCubitDoble cubit, {required Usuario usuario}) => MaterialApp(
  theme: AppTheme.light,
  home: MultiBlocProvider(
    providers: [
      BlocProvider<CitaCubit>.value(value: cubit),
      BlocProvider<AuthCubit>(
        create: (_) =>
            _AuthCubitDoble(AuthState(isAuthenticated: true, usuario: usuario)),
      ),
    ],
    child: const MisCitasDelDiaPage(),
  ),
);

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
