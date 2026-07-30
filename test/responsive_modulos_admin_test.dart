import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
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

Widget _app(Widget pagina, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: inner!,
  ),
  home: pagina,
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

void main() {
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
        _app(
          BlocProvider<SettingsCubit>(
            create: (_) => _SettingsCubitDoble(),
            child: const Scaffold(body: ConfiguracionPage()),
          ),
        ),
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
      _app(
        BlocProvider<SettingsCubit>(
          create: (_) => _SettingsCubitDoble(),
          child: const Scaffold(body: ConfiguracionPage()),
        ),
        textScale: 2,
      ),
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
