import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/actividad_planificada.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/pages/mis_citas_del_dia_page.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/widgets/resumen_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/widgets/selector_actividades_plan.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// SD-146. La cita referencia actividades del plan en vez de describirlas a
/// mano, y la agenda las resume sin obligar a abrir la cita.

class _CitaCubitDoble extends Cubit<CitaCubitState> implements CitaCubit {
  _CitaCubitDoble(super.initialState);

  @override
  Future<void> load({
    String? restringidoADoctorId,
    List<String>? doctorIdsPermitidos,
  }) async {}

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

/// Repositorio de prueba: devuelve lo que se le diga, o falla si se le pide.
class _CitaRepositoryDoble implements CitaRepository {
  _CitaRepositoryDoble({this.actividades = const [], this.fallo});

  final List<ActividadPlanificada> actividades;
  final Object? fallo;
  int llamadas = 0;

  @override
  Future<List<ActividadPlanificada>> getActividadesAgendables(
    String pacienteId,
  ) async {
    llamadas++;
    if (fallo != null) throw fallo!;
    return actividades;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} no se usa en la prueba',
  );
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

const _resina = ActividadPlanificada(
  itemPlanId: 'aaaa1111-1111-1111-1111-111111111111',
  nombreTratamiento: 'Resina compuesta',
  fdiDiente: 16,
  superficie: TipoSuperficie.oclusal,
  estado: EstadoItemPlan.aceptado,
  precioEstimado: 2500,
  orden: 1,
);

const _limpieza = ActividadPlanificada(
  itemPlanId: 'bbbb2222-2222-2222-2222-222222222222',
  nombreTratamiento: 'Profilaxis',
  estado: EstadoItemPlan.pendiente,
  precioEstimado: 1200,
  orden: 2,
);

Cita _cita({
  List<ActividadPlanificada> actividades = const [],
  String? motivo,
}) => Cita(
  id: '33333333-3333-3333-3333-333333333333',
  doctor: _doctor(),
  persona: _paciente(),
  date: DateTime(2026, 7, 22, 9, 30),
  duracionMinutos: 45,
  esEmergencia: false,
  estado: EstadoCita.confirmada,
  motivo: motivo,
  actividades: actividades,
);

CitaCubitLoaded _cargada({required List<Cita> citas}) => CitaCubitLoaded(
  citas: citas,
  focusedDay: _hoy,
  selectedDay: _hoy,
  viewMode: CalendarioViewMode.mensual,
);

Widget _agenda(_CitaCubitDoble cubit) => MaterialApp(
  theme: AppTheme.light,
  home: MultiBlocProvider(
    providers: [
      BlocProvider<CitaCubit>.value(value: cubit),
      BlocProvider<AuthCubit>(
        create: (_) => _AuthCubitDoble(
          AuthState(isAuthenticated: true, usuario: _doctor()),
        ),
      ),
    ],
    child: const MisCitasDelDiaPage(),
  ),
);

Widget _envoltura(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void _viewport(WidgetTester tester, [Size size = const Size(1280, 1000)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('modelo', () {
    test('la descripción junta procedimiento, pieza y cara', () {
      expect(_resina.descripcion, 'Resina compuesta · Pieza 16 · Oclusal');
      // Sin pieza ni cara queda solo el procedimiento: una profilaxis no se
      // hace sobre un diente concreto.
      expect(_limpieza.descripcion, 'Profilaxis');
    });

    test('un procedimiento sin nombre se dice, no se deja en blanco', () {
      const sinNombre = ActividadPlanificada(itemPlanId: 'x', fdiDiente: 21);
      expect(sinNombre.descripcion, 'Procedimiento sin nombre · Pieza 21');
    });

    test('el resumen respeta el orden del plan, no el de llegada', () {
      final cita = _cita(actividades: const [_limpieza, _resina]);
      expect(cita.resumenActividades, [
        'Resina compuesta · Pieza 16 · Oclusal',
        'Profilaxis',
      ]);
    });

    test('una cita sin actividades no es un error: la lista nace vacía', () {
      expect(_cita().actividades, isEmpty);
      expect(_cita().resumenActividades, isEmpty);
    });

    test('CitaModel lee las actividades que le inyecta el datasource', () {
      final modelo = CitaModel.fromJson({
        'id': '33333333-3333-3333-3333-333333333333',
        'fecha_hora': '2026-07-22T13:30:00Z',
        'duracion_minutos': 45,
        'es_emergencia': false,
        'estado': 'confirmada',
        'motivo': 'Dolor al morder',
        'doctor': {
          'doctor_id': '22222222-2222-2222-2222-222222222222',
          'nombre': 'Bartolomé',
          'apellido': 'Santana',
          'fecha_nacimiento': '1985-03-02',
          'cedula': '402-1234567-1',
          'estatus': 'activo',
          'username': 'bsantana',
          'password_hash': 'x',
          'especialidad': 'Endodoncia',
          'esta_disponible': true,
          'assistants': <dynamic>[],
          'contacto': {'email': '', 'numero_telefono': '', 'direccion': ''},
        },
        'persona': {
          'id': '11111111-1111-1111-1111-111111111111',
          'nombre': 'Ana',
          'apellido': 'Rodríguez',
          'fecha_nacimiento': '1990-05-12',
          'cedula': '001-1234567-8',
          'estatus': 'activo',
        },
        'actividades': [
          {
            'item_plan_id': 'aaaa1111-1111-1111-1111-111111111111',
            'tratamiento_nombre': 'Resina compuesta',
            'fdi_diente': 16,
            'superficie': 'oclusal',
            'estado': 'aceptado',
            'precio_estimado': 2500,
            'orden': 1,
          },
        ],
      });

      expect(modelo.actividades, hasLength(1));
      expect(modelo.actividades.single.nombreTratamiento, 'Resina compuesta');
      expect(modelo.actividades.single.fdiDiente, 16);
      expect(modelo.actividades.single.superficie, TipoSuperficie.oclusal);
      expect(modelo.actividades.single.estado, EstadoItemPlan.aceptado);
      // Y no viajan de vuelta como columna: `citas` no tiene esa columna.
      expect(modelo.toJson().containsKey('actividades'), isFalse);
    });

    test('sin la clave `actividades` el mapeo no revienta', () {
      final modelo = CitaModel.fromJson({
        'fecha_hora': '2026-07-22T13:30:00Z',
        'es_emergencia': false,
        'estado': 'programada',
        'doctor': {
          'doctor_id': '22222222-2222-2222-2222-222222222222',
          'nombre': 'B',
          'apellido': 'S',
          'fecha_nacimiento': '1985-03-02',
          'cedula': 'x',
          'estatus': 'activo',
          'username': 'b',
          'password_hash': 'x',
          'especialidad': 'x',
          'esta_disponible': true,
          'assistants': <dynamic>[],
          'contacto': {'email': '', 'numero_telefono': '', 'direccion': ''},
        },
        'persona': {
          'id': '11111111-1111-1111-1111-111111111111',
          'nombre': 'A',
          'apellido': 'R',
          'fecha_nacimiento': '1990-05-12',
          'cedula': 'y',
          'estatus': 'activo',
        },
      });
      expect(modelo.actividades, isEmpty);
    });
  });

  group('resumen de la cita', () {
    testWidgets('dice paciente, doctor, horario, duración, estado y plan', (
      tester,
    ) async {
      _viewport(tester);
      await tester.pumpWidget(
        _envoltura(
          TarjetaResumenCita(
            cita: _cita(
              actividades: const [_resina, _limpieza],
              motivo: 'Dolor al morder',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana Mercedes Rodríguez Montás'), findsOneWidget);
      expect(find.text('Dr. Bartolomé Santana Villalona'), findsOneWidget);
      expect(find.text('09:30 – 10:15 · 45 min'), findsOneWidget);
      expect(find.text('Confirmada'), findsOneWidget);
      expect(
        find.text('Resina compuesta · Pieza 16 · Oclusal'),
        findsOneWidget,
      );
      expect(find.text('Profilaxis'), findsOneWidget);
      // El motivo declarado no se sustituye por el plan: se muestra aparte.
      expect(find.text('MOTIVO DECLARADO'), findsOneWidget);
      expect(find.text('Dolor al morder'), findsOneWidget);
    });

    testWidgets('una emergencia lo advierte', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(
        _envoltura(
          TarjetaResumenCita(
            cita: Cita(
              doctor: _doctor(),
              persona: _paciente(),
              date: DateTime(2026, 7, 22, 9, 0),
              duracionMinutos: 90,
              esEmergencia: true,
              estado: EstadoCita.enEspera,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Emergencia'), findsOneWidget);
      expect(find.text('09:00 – 10:30 · 1 h 30 min'), findsOneWidget);
      // Sin actividades ni motivo el hueco se explica en vez de quedar vacío.
      expect(find.text('Sin actividades del plan vinculadas.'), findsOneWidget);
    });

    testWidgets('sin actividades pero con motivo, muestra el motivo', (
      tester,
    ) async {
      _viewport(tester);
      await tester.pumpWidget(
        _envoltura(TarjetaResumenCita(cita: _cita(motivo: 'Revisión anual'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Revisión anual'), findsOneWidget);
      expect(find.text('Sin actividades del plan vinculadas.'), findsNothing);
    });

    for (final size in const [
      Size(320, 900),
      Size(360, 900),
      Size(390, 900),
      Size(834, 1100),
      Size(1440, 900),
    ]) {
      testWidgets('el resumen se lee en ${size.width.toInt()} px', (
        tester,
      ) async {
        _viewport(tester, size);
        await tester.pumpWidget(
          _envoltura(
            TarjetaResumenCita(
              cita: _cita(
                actividades: const [_resina, _limpieza],
                motivo: 'Dolor al morder',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('agenda', () {
    testWidgets('la ficha del día muestra lo que se piensa tratar', (
      tester,
    ) async {
      _viewport(tester);
      final cubit = _CitaCubitDoble(
        _cargada(
          citas: [
            _cita(actividades: const [_resina, _limpieza]),
          ],
        ),
      );
      await tester.pumpWidget(_agenda(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Resina compuesta · Pieza 16 · Oclusal'), findsWidgets);
    });

    testWidgets('con más de dos actividades, la ficha dice cuántas faltan', (
      tester,
    ) async {
      _viewport(tester);
      const tercera = ActividadPlanificada(
        itemPlanId: 'cccc3333-3333-3333-3333-333333333333',
        nombreTratamiento: 'Extracción',
        fdiDiente: 48,
        orden: 3,
      );
      final cubit = _CitaCubitDoble(
        _cargada(
          citas: [
            _cita(actividades: const [_resina, _limpieza, tercera]),
          ],
        ),
      );
      await tester.pumpWidget(_agenda(cubit));
      await tester.pumpAndSettle();

      expect(find.text('+1 actividad más'), findsOneWidget);
    });

    for (final size in const [Size(320, 900), Size(390, 900)]) {
      testWidgets(
        'la ficha con actividades no desborda en ${size.width.toInt()} px',
        (tester) async {
          _viewport(tester, size);
          final cubit = _CitaCubitDoble(
            _cargada(
              citas: [
                _cita(
                  actividades: const [_resina, _limpieza],
                  motivo: 'Dolor al morder desde hace dos semanas',
                ),
              ],
            ),
          );
          await tester.pumpWidget(_agenda(cubit));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('el botón de resumen abre el diálogo con la lista completa', (
      tester,
    ) async {
      _viewport(tester);
      final cubit = _CitaCubitDoble(
        _cargada(
          citas: [
            _cita(actividades: const [_resina, _limpieza]),
          ],
        ),
      );
      await tester.pumpWidget(_agenda(cubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ver resumen de la cita').first);
      await tester.pumpAndSettle();

      expect(find.text('Resumen de la cita'), findsOneWidget);
      expect(find.text('SE PIENSA TRATAR'), findsOneWidget);
      expect(find.text('Profilaxis'), findsWidgets);
    });
  });

  group('selector de actividades', () {
    testWidgets('ofrece lo agendable y guarda lo que se marca', (tester) async {
      _viewport(tester);
      final repo = _CitaRepositoryDoble(
        actividades: const [_resina, _limpieza],
      );
      var seleccionadas = const <ActividadPlanificada>[];

      await tester.pumpWidget(
        _envoltura(
          StatefulBuilder(
            builder: (context, setState) => SelectorActividadesPlan(
              pacienteId: '11111111-1111-1111-1111-111111111111',
              repository: repo,
              seleccionadas: seleccionadas,
              onChanged: (lista) => setState(() => seleccionadas = lista),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Resina compuesta · Pieza 16 · Oclusal'),
        findsOneWidget,
      );
      expect(find.text('Aceptada'), findsOneWidget);
      expect(
        find.text('Sin actividades seleccionadas. La cita se agenda igual.'),
        findsOneWidget,
      );

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(seleccionadas, [_resina]);
      expect(find.text('1 actividad(es) seleccionada(s).'), findsOneWidget);
    });

    testWidgets('un paciente sin plan lo dice; no finge una lista', (
      tester,
    ) async {
      _viewport(tester);
      await tester.pumpWidget(
        _envoltura(
          SelectorActividadesPlan(
            pacienteId: '11111111-1111-1111-1111-111111111111',
            repository: _CitaRepositoryDoble(),
            seleccionadas: const [],
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Este paciente no tiene actividades pendientes en su plan de '
          'tratamiento.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('un paciente que aún no existe no se consulta', (tester) async {
      _viewport(tester);
      final repo = _CitaRepositoryDoble();
      await tester.pumpWidget(
        _envoltura(
          SelectorActividadesPlan(
            pacienteId: null,
            repository: repo,
            seleccionadas: const [],
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.llamadas, 0);
      expect(
        find.textContaining('este paciente aún no existe'),
        findsOneWidget,
      );
    });

    testWidgets('un fallo de carga se distingue de «no hay actividades»', (
      tester,
    ) async {
      _viewport(tester);
      final repo = _CitaRepositoryDoble(fallo: Exception('permiso denegado'));
      await tester.pumpWidget(
        _envoltura(
          SelectorActividadesPlan(
            pacienteId: '11111111-1111-1111-1111-111111111111',
            repository: repo,
            seleccionadas: const [],
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudo cargar el plan de tratamiento.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Este paciente no tiene actividades pendientes en su plan de '
          'tratamiento.',
        ),
        findsNothing,
      );

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(repo.llamadas, 2);
    });

    testWidgets(
      'una actividad que dejó de ser agendable se deselecciona sola',
      (tester) async {
        _viewport(tester);
        // El plan solo ofrece la profilaxis: la resina se rechazó entre medio.
        final repo = _CitaRepositoryDoble(actividades: const [_limpieza]);
        var seleccionadas = const <ActividadPlanificada>[_resina];

        await tester.pumpWidget(
          _envoltura(
            StatefulBuilder(
              builder: (context, setState) => SelectorActividadesPlan(
                pacienteId: '11111111-1111-1111-1111-111111111111',
                repository: repo,
                seleccionadas: seleccionadas,
                onChanged: (lista) => setState(() => seleccionadas = lista),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(seleccionadas, isEmpty);
      },
    );

    for (final size in const [Size(320, 900), Size(1440, 900)]) {
      testWidgets('el selector se lee en ${size.width.toInt()} px', (
        tester,
      ) async {
        _viewport(tester, size);
        await tester.pumpWidget(
          _envoltura(
            SelectorActividadesPlan(
              pacienteId: '11111111-1111-1111-1111-111111111111',
              repository: _CitaRepositoryDoble(
                actividades: const [_resina, _limpieza],
              ),
              seleccionadas: const [_resina],
              onChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
