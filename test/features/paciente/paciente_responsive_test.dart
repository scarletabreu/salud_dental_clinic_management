import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/historial_financiero_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/historial_financiero_state.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/categoria_condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/tipo_condicion.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/paciente_detail_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/paciente_form_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/pacientes_page.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/repositories/plan_tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/cubit/condiciones_paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/cubit/condiciones_paciente_state.dart';

const _pacienteId = '11111111-1111-1111-1111-111111111111';

class _PacienteCubitDoble extends Cubit<PacienteState>
    implements PacienteCubit {
  _PacienteCubitDoble(super.initialState);

  @override
  Future<void> loadById(String id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _AuthCubitDoble extends Cubit<AuthState> implements AuthCubit {
  _AuthCubitDoble(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _CondicionesCubitDoble extends Cubit<CondicionesPacienteState>
    implements CondicionesPacienteCubit {
  _CondicionesCubitDoble(super.initialState);

  @override
  Future<void> cargar() async {}

  @override
  Future<List<Condicion>> catalogo() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _HistorialCubitDoble extends Cubit<HistorialFinancieroState>
    implements HistorialFinancieroCubit {
  _HistorialCubitDoble(super.initialState);

  @override
  Future<void> cargar(String pacienteId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Paciente _paciente() => Paciente(
  id: _pacienteId,
  nombre: 'Ana Mercedes',
  apellido: 'Rodríguez Montás',
  birthDate: DateTime(1990, 5, 12),
  govID: '001-1234567-8',
  contactos: [
    Contacto(
      numeroTelefono: '809-555-0134',
      email: 'ana.rodriguez@correo.com.do',
      direccion: 'Calle Respaldo Central 45, Los Alcarrizos, Santo Domingo',
    ),
  ],
  estatus: EstatusPersona.activo,
  genero: Genero.femenino,
  trabajo: 'Docente de educación primaria',
  referencia: 'Referida por la Dra. Peralta',
  citas: const [],
  tipoPaciente: TipoPaciente.integrado,
  record: Record(
    pacienteId: _pacienteId,
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const ['Extracción de terceros molares en 2019'],
    historialFamiliar: 'Diabetes tipo 2 por línea materna e hipertensión',
  ),
);

/// El paciente vacío con el que la app abre el alta: la pantalla siempre recibe
/// uno, y en el alta viene sin datos.
Paciente _pacienteEnBlanco() => Paciente(
  nombre: '',
  apellido: '',
  birthDate: DateTime(1990),
  govID: '',
  contactos: const [],
  estatus: EstatusPersona.activo,
  genero: Genero.femenino,
  trabajo: '',
  referencia: '',
  citas: const [],
  tipoPaciente: TipoPaciente.integrado,
  record: Record(
    pacienteId: '',
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const [],
    historialFamiliar: '',
  ),
);

/// Plan vacío: `PlanesTratamientoCard` construye su cubit con `sl()`, así que
/// el expediente no se puede montar sin este repositorio registrado.
class _PlanRepoDoble implements PlanTratamientoRepository {
  @override
  Future<List<PlanTratamiento>> getPlanesPaciente(String pacienteId) async =>
      const [];

  @override
  Future<List<ItemPlanTratamiento>> getItemsEjecutables(
    String pacienteId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} no se usa aquí');
}

void _registrarCondiciones() {
  if (sl.isRegistered<CondicionesPacienteCubit>()) {
    sl.unregister<CondicionesPacienteCubit>();
  }
  if (sl.isRegistered<HistorialFinancieroCubit>()) {
    sl.unregister<HistorialFinancieroCubit>();
  }
  if (sl.isRegistered<PlanTratamientoRepository>()) {
    sl.unregister<PlanTratamientoRepository>();
  }
  sl.registerFactory<PlanTratamientoRepository>(_PlanRepoDoble.new);
  sl.registerFactory<HistorialFinancieroCubit>(
    () => _HistorialCubitDoble(const HistorialFinancieroInitial()),
  );
  sl.registerFactoryParam<CondicionesPacienteCubit, String, void>(
    (_, _) => _CondicionesCubitDoble(
      CondicionesPacienteLoaded([
        Condicion(
          id: 'cond-1',
          nombre: 'Hipertensión arterial controlada',
          tipo: TipoCondicion.patologica,
          categoria: CategoriaCondicion.cronica,
        ),
      ]),
    ),
  );
}

AuthState _authState({bool asistente = false}) => AuthState(
  isAuthenticated: true,
  usuario: asistente
      ? Asistente(
          id: 'asistente-1',
          nombre: 'Ana',
          apellido: 'Asistente',
          birthDate: DateTime(1990),
          govID: '001',
          contactos: const [],
          estatus: EstatusPersona.activo,
          username: 'asistente',
          shift: 'matutino',
        )
      : Admin(
          id: 'admin-1',
          nombre: 'Ada',
          apellido: 'Admin',
          birthDate: DateTime(1990),
          govID: '002',
          contactos: const [],
          estatus: EstatusPersona.activo,
          username: 'admin',
          specialty: 'General',
          assistants: const [],
          departamento: 'Clinica',
        ),
);

Widget _app(
  Widget pagina,
  PacienteState estado, {
  double textScale = 1,
  AuthState? authState,
}) => MaterialApp(
  key: ValueKey(authState?.rol),
  theme: AppTheme.light,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: inner!,
  ),
  home: MultiBlocProvider(
    providers: [
      BlocProvider<PacienteCubit>(create: (_) => _PacienteCubitDoble(estado)),
      BlocProvider<AuthCubit>(
        create: (_) => _AuthCubitDoble(authState ?? _authState()),
      ),
    ],
    child: pagina,
  ),
);

void _viewport(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final _viewports = <String, Size>{
  '320 px': const Size(320, 1000),
  '360 px': const Size(360, 1000),
  '390 px': const Size(390, 1000),
  'tablet': const Size(768, 1024),
  'escritorio': const Size(1280, 1000),
};

void main() {
  setUp(_registrarCondiciones);

  tearDown(() {
    if (sl.isRegistered<CondicionesPacienteCubit>()) {
      sl.unregister<CondicionesPacienteCubit>();
    }
    if (sl.isRegistered<HistorialFinancieroCubit>()) {
      sl.unregister<HistorialFinancieroCubit>();
    }
    if (sl.isRegistered<PlanTratamientoRepository>()) {
      sl.unregister<PlanTratamientoRepository>();
    }
  });

  _viewports.forEach((nombre, tamano) {
    testWidgets('el alta de paciente se puede completar en $nombre', (
      tester,
    ) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(
          PacienteFormPage(paciente: _pacienteEnBlanco()),
          const PacienteLoaded(todos: [], filtrados: []),
        ),
      );
      await tester.pumpAndSettle();

      // 'Ana' es el hint del campo Nombre, no su valor: así se localiza el
      // campo en un formulario vacío.
      final nombreCampo = find.widgetWithText(TextFormField, 'Ana');
      expect(nombreCampo, findsOneWidget);
      await tester.enterText(nombreCampo, 'Ana Mercedes');
      await tester.pump();

      expect(find.text('Ana Mercedes'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'el formulario de paciente no debe desbordar en $nombre',
      );
    });

    testWidgets('el expediente del paciente se lee en $nombre', (tester) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(
          const PacienteDetailPage(pacienteId: _pacienteId),
          PacienteDetailLoaded(_paciente()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'el expediente no debe desbordar en $nombre',
      );
    });
  });

  testWidgets('el alta de paciente resiste el teclado abierto en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 640));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);

    await tester.pumpWidget(
      _app(
        PacienteFormPage(paciente: _pacienteEnBlanco()),
        const PacienteLoaded(todos: [], filtrados: []),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('el expediente resiste el texto ampliado en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 2400));
    await tester.pumpWidget(
      _app(
        const PacienteDetailPage(pacienteId: _pacienteId),
        PacienteDetailLoaded(_paciente()),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('solo roles clínicos pueden exportar el expediente', (
    tester,
  ) async {
    _viewport(tester, const Size(900, 900));
    final estado = PacienteDetailLoaded(_paciente());

    await tester.pumpWidget(
      _app(
        const PacienteDetailPage(pacienteId: _pacienteId),
        estado,
        authState: _authState(asistente: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exportar_expediente_button')), findsNothing);

    await tester.pumpWidget(
      _app(
        const PacienteDetailPage(pacienteId: _pacienteId),
        estado,
        authState: _authState(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exportar_expediente_button')), findsOneWidget);
  });

  // Antes el botón se pintaba igual y, al tocarlo, moría en un SnackBar. QA lo
  // marcó como defecto D18 (1 ago 2026): no se ofrecen acciones imposibles.
  testWidgets('no ofrece el expediente si falla el historial', (
    tester,
  ) async {
    _viewport(tester, const Size(900, 900));
    await tester.pumpWidget(
      _app(
        const PacienteDetailPage(pacienteId: _pacienteId),
        PacienteDetailLoaded(_paciente(), historialNoDisponible: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exportar_expediente_button')), findsNothing);
    expect(find.text('Generar Expediente Clínico'), findsNothing);
  });

  _viewports.forEach((nombre, tamano) {
    testWidgets('el listado de pacientes se lee en $nombre', (tester) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(
          const Scaffold(body: PacientesPage()),
          PacienteLoaded(todos: [_paciente()], filtrados: [_paciente()]),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'el listado de pacientes no debe desbordar en $nombre',
      );
    });
  });

  testWidgets('el listado de pacientes resiste el texto ampliado en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 1600));
    await tester.pumpWidget(
      _app(
        const Scaffold(body: PacientesPage()),
        PacienteLoaded(todos: [_paciente()], filtrados: [_paciente()]),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
