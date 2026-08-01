import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/entities/regla_clinica.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/repositories/regla_clinica_repository.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/presentation/cubit/reglas_clinicas_cubit.dart';
import 'package:salud_dental_clinic_management/features/configuracion/presentation/cubit/settings_cubit.dart';
import 'package:salud_dental_clinic_management/features/configuracion/presentation/pages/configuracion_page.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/cubit/equipo_cubit.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/cubit/equipo_state.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/pages/crear_editar_equipo_page.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/pages/equipo_list_page.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/cubit/personal_perfiles_cubit.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/cubit/personal_perfiles_state.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/pages/usuarios_list_page.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/widgets/tratamiento_card.dart';
import 'support/sesion_de_prueba.dart';

class _EquipoCubitDoble extends Cubit<EquipoState> implements EquipoCubit {
  _EquipoCubitDoble(super.initialState);

  @override
  Future<void> cargarEquipos() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PerfilesCubitDoble extends Cubit<PersonalPerfilesState>
    implements PersonalPerfilesCubit {
  _PerfilesCubitDoble(super.initialState);

  @override
  Future<void> cargarUsuarios() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _SettingsCubitDoble extends Cubit<SettingsState>
    implements SettingsCubit {
  _SettingsCubitDoble()
    : super(SettingsState(themeMode: ThemeMode.light, languageCode: 'es'));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

List<Equipo> _equipos() => [
  Equipo(
    id: 'eq-1',
    nombre: 'Autoclave de vapor clase B 23 litros',
    descripcion:
        'Esterilizador de mesa para instrumental crítico, con ciclo de '
        'vacío fraccionado y registro de trazabilidad.',
    ultimoMantenimiento: DateTime(2026, 4, 15),
    tiempoParaMantenimiento: 180,
  ),
  Equipo(
    id: 'eq-2',
    nombre: 'Rayos X periapical',
    descripcion: 'Equipo radiográfico intraoral montado en pared.',
    ultimoMantenimiento: DateTime(2026, 1, 10),
    tiempoParaMantenimiento: 365,
  ),
];

List<Usuario> _usuarios() => [
  Doctor(
    id: 'u-1',
    nombre: 'Bartolomé',
    apellido: 'Santana Villalona',
    birthDate: DateTime(1985, 3, 2),
    govID: '402-1234567-1',
    contactos: [
      Contacto(
        numeroTelefono: '809-555-0134',
        email: 'b.santana@clinica.do',
        direccion: 'Santo Domingo',
      ),
    ],
    estatus: EstatusPersona.activo,
    username: 'bsantana',
    specialty: 'Endodoncia y rehabilitación oral',
    assistants: const [],
  ),
];

Tratamiento _tratamiento() => Tratamiento(
  id: 'tr-1',
  nombre: 'Endodoncia multirradicular con reconstrucción de muñón',
  descripcion:
      'Tratamiento de conductos en molares, incluye instrumentación '
      'rotatoria, obturación y reconstrucción del muñón.',
  costo: 18500.75,
  contraindicaciones: const [],
  alcance: Alcance.diente,
);

/// La sesión bajo la que se pinta la configuración.
///
/// Desde HFX-CLIN-006 la pantalla ofrece los umbrales clínicos sólo a quien
/// ejerce, así que necesita saber quién está conectado. Montarla sin sesión ya
/// no representa nada que ocurra en la app: allí siempre hay una.
class _AuthCubitDoble extends Cubit<AuthState> implements AuthCubit {
  _AuthCubitDoble(RolUsuario rol)
    : super(
        AuthState(
          isAuthenticated: true,
          usuario: rol == RolUsuario.admin
              ? Admin(
                  id: 'admin-1',
                  nombre: 'Alma',
                  apellido: 'Dirección',
                  birthDate: DateTime(1980),
                  govID: '001-0000001-1',
                  contactos: const [],
                  estatus: EstatusPersona.activo,
                  username: 'adireccion',
                  specialty: 'General',
                  assistants: const [],
                  departamento: 'Dirección',
                )
              : Asistente(
                  id: 'asis-1',
                  nombre: 'Rita',
                  apellido: 'Recepción',
                  birthDate: DateTime(1995),
                  govID: '001-0000002-2',
                  contactos: const [],
                  estatus: EstatusPersona.activo,
                  username: 'rrecepcion',
                  shift: 'matutino',
                ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// La configuración, montada con la sesión y las dependencias que la app le da.
Widget _configuracion({RolUsuario rol = RolUsuario.admin}) => MultiBlocProvider(
  providers: [
    BlocProvider<AuthCubit>(create: (_) => _AuthCubitDoble(rol)),
    BlocProvider<SettingsCubit>(create: (_) => _SettingsCubitDoble()),
  ],
  child: const Scaffold(body: ConfiguracionPage()),
);

Widget _app(Widget pagina, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: inner!,
  ),
  // Estas pantallas son las del admin: es su maquetación la que se mide, y es
  // el admin quien ve precios y botones de edición del catálogo.
  home: proveedorSesion(RolUsuario.admin, child: pagina),
);

void _viewport(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final _viewports = <String, Size>{
  '320 px': const Size(320, 900),
  '360 px': const Size(360, 900),
  '390 px': const Size(390, 900),
  'tablet': const Size(768, 1024),
  'escritorio': const Size(1280, 900),
};

/// Reglas suficientes para que la sección se pinte con contenido real: una
/// pantalla vacía no comprueba que el texto quepa.
class _ReglasRepoDoble implements ReglaClinicaRepository {
  @override
  Future<List<ReglaClinica>> getReglasVigentes() async => const [
    ReglaClinica(
      id: 'r1',
      codigo: 'COMB_HIPERTENSION_SIGNOS',
      version: 1,
      nombre: 'Hipertensión con presión alterada',
      descripcion: 'Vigila la presión en pacientes con hipertensión arterial.',
      categoria: 'condicion',
      tipo: TipoRegla.combinacionCondicionSigno,
      parametros: ParametrosRegla(
        condicion: 'hipertensión',
        signos: [
          UmbralSigno(codigo: 'presion_sistolica', maximo: 160),
          UmbralSigno(codigo: 'presion_diastolica', maximo: 100),
        ],
      ),
      severidad: SeveridadAlerta.critica,
      accion: AccionAlerta.documentar,
      estado: EstadoRegla.aprobada,
      editable: true,
    ),
  ];

  @override
  Future<List<SignoVitalCatalogo>> getCatalogoSignosVitales() async => const [
    SignoVitalCatalogo(
      codigo: 'presion_sistolica',
      etiqueta: 'Presión sistólica',
      unidad: 'mmHg',
      minimoPosible: 30,
      maximoPosible: 300,
    ),
  ];

  @override
  Future<ResultadoPublicacion> publicar(ReglaClinica regla, {String? nota}) async =>
      ResultadoPublicacion(
        codigo: regla.codigo,
        version: regla.version,
        sinCambios: true,
      );
}

void main() {
  setUpAll(() {
    // La pantalla resuelve el cubit por el service locator, como el resto de
    // la app; sin registrarlo aquí la sección del admin no llegaría a pintarse.
    if (!sl.isRegistered<ReglasClinicasCubit>()) {
      sl.registerFactory<ReglasClinicasCubit>(
        () => ReglasClinicasCubit(_ReglasRepoDoble()),
      );
    }
  });

  tearDownAll(() {
    if (sl.isRegistered<ReglasClinicasCubit>()) {
      sl.unregister<ReglasClinicasCubit>();
    }
  });

  testWidgets('recepción no ve los umbrales clínicos en configuración', (
    tester,
  ) async {
    // Mover un umbral es una decisión médica: la sección no se le ofrece a
    // quien después no podría guardarla.
    _viewport(tester, const Size(1280, 900));
    await tester.pumpWidget(_app(_configuracion(rol: RolUsuario.asistente)));
    await tester.pumpAndSettle();

    expect(find.text('REGLAS CLÍNICAS'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quien ejerce ve los umbrales clínicos en configuración', (
    tester,
  ) async {
    _viewport(tester, const Size(1280, 900));
    await tester.pumpWidget(_app(_configuracion()));
    await tester.pumpAndSettle();

    expect(find.text('REGLAS CLÍNICAS'), findsOneWidget);
    expect(find.text('Hipertensión con presión alterada'), findsOneWidget);
  });

  _viewports.forEach((nombre, tamano) {
    testWidgets('el listado de equipos se lee en $nombre', (tester) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(
          BlocProvider<EquipoCubit>(
            create: (_) => _EquipoCubitDoble(
              EquipoLoaded(todos: _equipos(), filtrados: _equipos()),
            ),
            child: const EquipoListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'el listado de equipos no debe desbordar en $nombre',
      );
    });

    testWidgets('el alta de equipo se puede completar en $nombre', (
      tester,
    ) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(
          BlocProvider<EquipoCubit>(
            create: (_) =>
                _EquipoCubitDoble(const EquipoLoaded(todos: [], filtrados: [])),
            child: const CrearEditarEquipoPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final campos = find.byType(TextFormField);
      expect(campos, findsWidgets);
      await tester.enterText(campos.first, 'Compresor dental');
      await tester.pump();

      expect(find.text('Compresor dental'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'el formulario de equipo no debe desbordar en $nombre',
      );
    });

    testWidgets('el listado de perfiles se lee en $nombre', (tester) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(
          BlocProvider<PersonalPerfilesCubit>(
            create: (_) => _PerfilesCubitDoble(
              PerfilLoaded(todos: _usuarios(), filtrados: _usuarios()),
            ),
            child: const UsuariosListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'el listado de perfiles no debe desbordar en $nombre',
      );
    });

    testWidgets('la tarjeta de tratamiento se lee en $nombre', (tester) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(
              child: TratamientoCard(
                tratamiento: _tratamiento(),
                onEdit: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'la tarjeta de tratamiento no debe desbordar en $nombre',
      );
    });

    testWidgets('la configuración se lee en $nombre', (tester) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(
        _app(_configuracion()),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'la configuración no debe desbordar en $nombre',
      );
    });
  });

  testWidgets('la configuración resiste el texto ampliado en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 1600));
    await tester.pumpWidget(
      _app(_configuracion(), textScale: 2),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('el listado de equipos resiste el texto ampliado en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 1600));
    await tester.pumpWidget(
      _app(
        BlocProvider<EquipoCubit>(
          create: (_) => _EquipoCubitDoble(
            EquipoLoaded(todos: _equipos(), filtrados: _equipos()),
          ),
          child: const EquipoListPage(),
        ),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
