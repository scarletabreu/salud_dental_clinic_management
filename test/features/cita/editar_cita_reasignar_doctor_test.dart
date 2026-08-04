import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/actividad_planificada.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/pages/cita_edit_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

/// Editar cita ofrecía a **todo el mundo** un desplegable con la plantilla
/// entera de odontólogos.
///
/// Era el último sitio por donde un doctor veía a los demás doctores después de
/// cerrar la RLS (D11, 3 ago 2026): la lista no llega por la tabla sino por
/// `get_active_doctors`, que es SECURITY DEFINER y por tanto no la recorta
/// ninguna policy. Además ofrecía una reasignación que `citas_update` iba a
/// rechazar de todas formas.
void main() {
  setUp(() {
    sl.registerFactory<DoctorRepository>(_DoctorRepositorioDoble.new);
    sl.registerFactory<CitaRepository>(_CitaRepositorioDoble.new);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('el doctor ve su nombre fijo, sin desplegable de odontólogos', (
    tester,
  ) async {
    _viewport(tester);
    await tester.pumpWidget(_app(usuario: _doctorPropio));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('doctor_asignado_fijo')),
      findsOneWidget,
      reason: 'debe verse a quién está asignada la cita, sin poder cambiarlo',
    );
    expect(
      find.byType(DropdownButtonFormField<Doctor>),
      findsNothing,
      reason: 'un doctor no reasigna citas ni ve la plantilla de la clínica',
    );
    expect(
      find.textContaining('Guzmán'),
      findsNothing,
      reason: 'el nombre de otro odontólogo no debe aparecer en la pantalla',
    );
  });

  testWidgets('quien gestiona la agenda completa sí puede reasignar', (
    tester,
  ) async {
    _viewport(tester);
    await tester.pumpWidget(_app(usuario: _admin));
    await tester.pumpAndSettle();

    expect(
      find.byType(DropdownButtonFormField<Doctor>),
      findsOneWidget,
      reason: 'el admin gestiona la agenda de toda la clínica',
    );
    expect(find.byKey(const Key('doctor_asignado_fijo')), findsNothing);
  });
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app({required Usuario usuario}) => MaterialApp(
  theme: AppTheme.light,
  home: MultiBlocProvider(
    providers: [
      BlocProvider<CitaCubit>(create: (_) => _CitaCubitDoble()),
      BlocProvider<AuthCubit>(
        create: (_) =>
            _AuthCubitDoble(AuthState(isAuthenticated: true, usuario: usuario)),
      ),
    ],
    child: CitaEditPage(cita: _cita),
  ),
);

class _AuthCubitDoble extends Cubit<AuthState> implements AuthCubit {
  _AuthCubitDoble(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CitaCubitDoble extends Cubit<CitaCubitState> implements CitaCubit {
  _CitaCubitDoble() : super(const CitaCubitLoading());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DoctorRepositorioDoble implements DoctorRepository {
  @override
  Future<List<Doctor>> getDoctores() async => [_doctorPropio, _otroDoctor];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CitaRepositorioDoble implements CitaRepository {
  @override
  Future<List<ActividadPlanificada>> actividadesAgendables(
    String pacienteId,
  ) async => const [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Doctor _crearDoctor(String id, String nombre, String apellido) => Doctor(
  id: id,
  nombre: nombre,
  apellido: apellido,
  birthDate: DateTime(1985, 3, 2),
  govID: '402-1234567-1',
  contactos: const <Contacto>[],
  estatus: EstatusPersona.activo,
  username: nombre.toLowerCase(),
  specialty: 'Endodoncia',
  assistants: const [],
);

final _doctorPropio = _crearDoctor('doctor-1', 'Bartolomé', 'Santana');
final _otroDoctor = _crearDoctor('doctor-2', 'Elena', 'Guzmán');

final _admin = Admin(
  id: 'admin-1',
  nombre: 'Alma',
  apellido: 'Dirección',
  birthDate: DateTime(1978, 4, 12),
  govID: '402-7654321-9',
  contactos: const <Contacto>[],
  estatus: EstatusPersona.activo,
  username: 'alma',
  specialty: 'General',
  assistants: const [],
  departamento: 'Dirección',
);

final _paciente = Paciente(
  id: 'pac-1',
  nombre: 'Zoila',
  apellido: 'Pérez',
  birthDate: DateTime(1995, 5, 5),
  govID: '001-1111111-1',
  contactos: const <Contacto>[],
  estatus: EstatusPersona.activo,
  genero: Genero.femenino,
  tipoPaciente: TipoPaciente.integrado,
  trabajo: '',
  referencia: '',
  citas: const [],
  record: Record(
    pacienteId: 'pac-1',
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const [],
    historialFamiliar: '',
  ),
);

final _cita = Cita(
  id: 'cita-1',
  persona: _paciente,
  doctor: _doctorPropio,
  date: DateTime(2026, 8, 4, 9),
  duracionMinutos: 30,
  esEmergencia: false,
  estado: EstadoCita.confirmada,
);
