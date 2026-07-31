import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/supabase_storage_helper.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/cita/data/datasources/cita_remote_datasources.dart';
import 'package:salud_dental_clinic_management/features/cita/data/repositories/cita_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/referencia_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/errors/cancelacion_con_consulta_abierta.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/consulta_abierta_lookup.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta_de_cita.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/inicio_consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/crear_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SD-160 · Coherencia entre la agenda y la lista de consultas.
///
/// Las reglas que sostienen que ambas pantallas cuenten lo mismo: la consulta
/// se fecha con su cita, una cita con consulta abierta no se cancela, y el
/// alcance por rol es el mismo en los dos listados. Los tests atacan las clases
/// reales; los dobles sustituyen únicamente red y almacenamiento.
void main() {
  group('la consulta hereda la fecha de su cita', () {
    test(
      'una cita futura fija la fecha de la consulta, no el día del clic',
      () async {
        final agendada = DateTime(2026, 8, 14, 15, 30);
        final consultas = _ConsultaRepoFalso();
        final cubit = _consultaCubit(
          crear: _CrearConsultaEspia(),
          citas: _CitaRepoFalso(referencias: {'cita-1': _enEspera(agendada)}),
          consultas: consultas,
        );

        await cubit.iniciar(
          pacienteId: _pacienteId,
          doctorId: 'doctor-1',
          citaId: 'cita-1',
          motivoConsulta: 'control',
          tempCondiciones: const [],
          adjuntos: const [],
        );

        expect(
          consultas.iniciada?.fecha,
          agendada,
          reason:
              'la consulta abierta desde una cita de agosto tiene que quedar en '
              'el día y la hora agendados, no en el momento de abrirla',
        );
        await cubit.close();
      },
    );

    test('sin cita (walk-in) la fecha es el momento de la atención', () async {
      final crear = _CrearConsultaEspia();
      final cubit = _consultaCubit(crear: crear, citas: _CitaRepoFalso());

      final antes = DateTime.now();
      await cubit.iniciar(
        pacienteId: _pacienteId,
        doctorId: 'doctor-1',
        motivoConsulta: 'urgencia',
        tempCondiciones: const [],
        adjuntos: const [],
      );
      final despues = DateTime.now();

      final fecha = crear.recibida!.fecha;
      expect(fecha.isBefore(antes), isFalse);
      expect(fecha.isAfter(despues), isFalse);
      await cubit.close();
    });

    test('la cita pasa a enConsulta dentro de la misma operación', () async {
      // HFX-CLIN-004: la transición dejó de ser una segunda llamada del cliente.
      // La hace `iniciar_consulta_de_cita` en la transacción que crea la
      // consulta, así que ya no puede quedar una consulta abierta sobre una
      // cita que sigue «en espera» porque se cayó la red entre ambas.
      final citas = _CitaRepoFalso(
        referencias: {'cita-1': _enEspera(DateTime(2026, 8, 14, 9, 0))},
      );
      final consultas = _ConsultaRepoFalso();
      final cubit = _consultaCubit(
        crear: _CrearConsultaEspia(),
        citas: citas,
        consultas: consultas,
      );

      await cubit.iniciar(
        pacienteId: _pacienteId,
        doctorId: 'doctor-1',
        citaId: 'cita-1',
        motivoConsulta: 'control',
        tempCondiciones: const [],
        adjuntos: const [],
      );

      expect(consultas.iniciada?.citaId, 'cita-1');
      expect(
        citas.estadosEscritos,
        isEmpty,
        reason: 'el estado de la cita lo mueve la base, no el cliente',
      );
      await cubit.close();
    });

    test('reintentar sobre una cita ya abierta reanuda la misma consulta', () async {
      final consultas = _ConsultaRepoFalso(
        estado: EstadoInicioConsulta.reanudada,
        detalle: Consulta(
          id: 'consulta-1',
          pacienteId: _pacienteId,
          doctorId: 'doctor-1',
          citaId: 'cita-1',
          fecha: DateTime(2026, 8, 14, 9, 0),
        ),
      );
      final cubit = _consultaCubit(
        crear: _CrearConsultaEspia(),
        citas: _CitaRepoFalso(
          referencias: {'cita-1': _enEspera(DateTime(2026, 8, 14, 9, 0))},
        ),
        consultas: consultas,
      );

      await cubit.iniciar(
        pacienteId: _pacienteId,
        doctorId: 'doctor-1',
        citaId: 'cita-1',
        motivoConsulta: 'control',
        tempCondiciones: const [],
        adjuntos: const [],
      );

      final estado = cubit.state;
      expect(estado, isA<ConsultaIniciada>());
      expect((estado as ConsultaIniciada).consulta.id, 'consulta-1');
      await cubit.close();
    });

    test('una cita ya atendida no se reabre', () async {
      final consultas = _ConsultaRepoFalso(
        estado: EstadoInicioConsulta.finalizada,
      );
      final cubit = _consultaCubit(
        crear: _CrearConsultaEspia(),
        citas: _CitaRepoFalso(
          referencias: {'cita-1': _enEspera(DateTime(2026, 8, 14, 9, 0))},
        ),
        consultas: consultas,
      );

      await cubit.iniciar(
        pacienteId: _pacienteId,
        doctorId: 'doctor-1',
        citaId: 'cita-1',
        motivoConsulta: 'control',
        tempCondiciones: const [],
        adjuntos: const [],
      );

      expect(cubit.state, isA<ConsultaError>());
      expect((cubit.state as ConsultaError).message, contains('ya fue atendida'));
      await cubit.close();
    });

    test('una cita inexistente falla sin crear la consulta', () async {
      final crear = _CrearConsultaEspia();
      final cubit = _consultaCubit(crear: crear, citas: _CitaRepoFalso());

      await cubit.iniciar(
        pacienteId: _pacienteId,
        doctorId: 'doctor-1',
        citaId: 'cita-fantasma',
        motivoConsulta: 'control',
        tempCondiciones: const [],
        adjuntos: const [],
      );

      expect(cubit.state, isA<ConsultaError>());
      expect(
        crear.recibida,
        isNull,
        reason: 'fallar después de crearla dejaría una consulta huérfana',
      );
      await cubit.close();
    });
  });

  group('enConsulta es alcanzable', () {
    test('enEspera puede pasar a enConsulta', () {
      expect(
        EstadoCita.enEspera.puedeTransicionarA(EstadoCita.enConsulta),
        isTrue,
        reason:
            'sin esta arista ninguna cita entra en consulta y toda consulta '
            'abierta desde la agenda falla',
      );
    });

    test('algún estado alcanza enConsulta', () {
      expect(
        EstadoCita.values.where(
          (e) => e.puedeTransicionarA(EstadoCita.enConsulta),
        ),
        isNotEmpty,
      );
    });
  });

  group('no se cancela una cita con su consulta abierta', () {
    test(
      'cancelar con consulta abierta falla con mensaje accionable',
      () async {
        final datasource = _CitaDatasourceFalso(EstadoCita.enConsulta);
        final repo = CitaRepositoryImpl(
          remoteDataSource: datasource,
          consultaAbiertaLookup: _LookupFalso(const {
            'cita-1': ConsultaDeCita(id: 'c-1', finalizada: false),
          }),
        );

        await expectLater(
          repo.updateCitaEstado('cita-1', EstadoCita.cancelada),
          throwsA(isA<CancelacionConConsultaAbierta>()),
        );
        expect(
          datasource.estadoEscrito,
          isNull,
          reason: 'la cancelación no debe llegar a la base',
        );
        expect(
          const CancelacionConConsultaAbierta().toString(),
          contains('Finaliza o elimina la consulta'),
        );
      },
    );

    test('con la consulta ya finalizada la cancelación procede', () async {
      final datasource = _CitaDatasourceFalso(EstadoCita.enConsulta);
      final repo = CitaRepositoryImpl(
        remoteDataSource: datasource,
        consultaAbiertaLookup: _LookupFalso(const {
          'cita-1': ConsultaDeCita(id: 'c-1', finalizada: true),
        }),
      );

      await repo.updateCitaEstado('cita-1', EstadoCita.cancelada);

      expect(datasource.estadoEscrito, EstadoCita.cancelada);
    });

    test('sin consulta asociada la cancelación procede', () async {
      final datasource = _CitaDatasourceFalso(EstadoCita.enEspera);
      final repo = CitaRepositoryImpl(
        remoteDataSource: datasource,
        consultaAbiertaLookup: _LookupFalso(const {}),
      );

      await repo.updateCitaEstado('cita-1', EstadoCita.cancelada);

      expect(datasource.estadoEscrito, EstadoCita.cancelada);
    });

    test('completar una cita con consulta abierta sí se permite', () async {
      // Cerrar es el camino correcto: solo se bloquea cancelar.
      final datasource = _CitaDatasourceFalso(EstadoCita.enConsulta);
      final repo = CitaRepositoryImpl(
        remoteDataSource: datasource,
        consultaAbiertaLookup: _LookupFalso(const {
          'cita-1': ConsultaDeCita(id: 'c-1', finalizada: false),
        }),
      );

      await repo.updateCitaEstado('cita-1', EstadoCita.completada);

      expect(datasource.estadoEscrito, EstadoCita.completada);
    });
  });

  group('alcance por rol en ambos listados', () {
    test('el doctor pide al servidor solo sus citas', () async {
      final repo = _CitaRepoFalso();
      final cubit = CitaCubit(repo);

      await cubit.load(restringidoADoctorId: 'doctor-1');

      expect(
        repo.llamadas,
        ['getCitasByDoctor:doctor-1'],
        reason:
            'la agenda del doctor no debe traerse la clínica entera para '
            'descartarla en el cliente',
      );
      await cubit.close();
    });

    test('admin y asistente conservan la vista global', () async {
      final repo = _CitaRepoFalso();
      final cubit = CitaCubit(repo);

      await cubit.load();

      expect(repo.llamadas, ['getCitas']);
      await cubit.close();
    });

    test('el alcance del doctor sobrevive a un load() sin argumentos', () async {
      // Las pantallas refrescan con `load()` pelado; si el alcance se perdiera
      // ahí, el doctor vería de golpe la agenda de toda la clínica.
      final repo = _CitaRepoFalso();
      final cubit = CitaCubit(repo);

      await cubit.load(restringidoADoctorId: 'doctor-1');
      await cubit.load();

      expect(repo.llamadas, [
        'getCitasByDoctor:doctor-1',
        'getCitasByDoctor:doctor-1',
      ]);
      await cubit.close();
    });

    test('la lista de consultas restringe al mismo doctor', () async {
      // La contraparte: `ConsultasListCubit` ya pide `getConsultasByDoctor`.
      // Ambos listados tienen que restringir por el mismo id o nunca cuadran.
      final consultas = _ConsultaRepoFalso();

      await consultas.getConsultasByDoctor('doctor-1');

      expect(consultas.llamadas, ['getConsultasByDoctor:doctor-1']);
    });
  });

  group('la agenda conoce la consulta de cada cita', () {
    test('el estado expone la consulta por citaId', () async {
      final repo = _CitaRepoFalso(citas: [_citaDe('cita-1', 'doctor-1')]);
      final cubit = CitaCubit(
        repo,
        _LookupFalso(const {
          'cita-1': ConsultaDeCita(id: 'c-1', finalizada: false),
        }),
      );

      await cubit.load();

      final estado = cubit.state as CitaCubitLoaded;
      expect(estado.consultaDe(estado.citas.first)?.id, 'c-1');
      expect(estado.consultaDe(estado.citas.first)?.estaAbierta, isTrue);
      await cubit.close();
    });

    test('una cita sin consulta no aparece en el mapa', () async {
      final repo = _CitaRepoFalso(citas: [_citaDe('cita-9', 'doctor-1')]);
      final cubit = CitaCubit(repo, _LookupFalso(const {}));

      await cubit.load();

      final estado = cubit.state as CitaCubitLoaded;
      expect(estado.consultaDe(estado.citas.first), isNull);
      await cubit.close();
    });
  });
}

// El repositorio real rechaza ids que no sean uuid ("paciente de prueba").
const _pacienteId = '11111111-1111-1111-1111-111111111111';

Cita _citaDe(String id, String doctorId) => Cita(
  id: id,
  doctor: Doctor(
    id: doctorId,
    nombre: 'Ada',
    apellido: 'Lovelace',
    birthDate: DateTime(1980, 1, 1),
    govID: '001-0000000-1',
    contactos: const [],
    estatus: EstatusPersona.activo,
    username: 'ada',
    specialty: 'general',
    assistants: const [],
  ),
  persona: Persona(
    id: 'persona-1',
    nombre: 'Ana',
    apellido: 'Pérez',
    birthDate: DateTime(1990, 5, 12),
    govID: '001-1234567-8',
    contactos: const [],
    estatus: EstatusPersona.activo,
  ),
  date: DateTime(2026, 8, 14, 10, 0),
  duracionMinutos: 30,
  esEmergencia: false,
  estado: EstadoCita.enEspera,
);

ReferenciaCita _enEspera(DateTime fechaHora) => ReferenciaCita(
  id: 'cita-1',
  fechaHora: fechaHora,
  estado: EstadoCita.enEspera,
  doctorId: 'doctor-1',
);

ConsultaCubit _consultaCubit({
  required _CrearConsultaEspia crear,
  required _CitaRepoFalso citas,
  _ConsultaRepoFalso? consultas,
}) => ConsultaCubit(
  crear,
  _StorageNoUsado(),
  citas,
  consultas ?? _ConsultaRepoFalso(),
);

/// Captura la consulta que se manda a crear, que es donde se observa la fecha.
class _CrearConsultaEspia extends Fake implements CrearConsultaUseCase {
  Consulta? recibida;

  @override
  Future<String> call(Consulta consulta) async {
    recibida = consulta;
    return 'consulta-1';
  }
}

class _CitaRepoFalso extends Fake implements CitaRepository {
  final Map<String, ReferenciaCita> referencias;
  final List<Cita> citas;
  final llamadas = <String>[];
  final estadosEscritos = <EstadoCita>[];

  _CitaRepoFalso({this.referencias = const {}, this.citas = const []});

  @override
  Future<ReferenciaCita?> getReferenciaCita(String id) async => referencias[id];

  @override
  Future<void> updateCitaEstado(String id, EstadoCita nuevoEstado) async {
    estadosEscritos.add(nuevoEstado);
  }

  @override
  Future<List<Cita>> getCitas() async {
    llamadas.add('getCitas');
    return citas;
  }

  @override
  Future<List<Cita>> getCitasByDoctor(String doctorId) async {
    llamadas.add('getCitasByDoctor:$doctorId');
    return citas.where((c) => c.doctor.id == doctorId).toList();
  }
}

/// Subclase del datasource real: solo se interceptan las dos operaciones que
/// tocarían la red, así la validación del repositorio se ejerce de verdad.
class _CitaDatasourceFalso extends CitaRemoteDataSource {
  final EstadoCita estadoActual;
  EstadoCita? estadoEscrito;

  _CitaDatasourceFalso(this.estadoActual)
    : super(SupabaseClient('https://example.supabase.co', 'test-key'));

  @override
  Future<EstadoCita> fetchEstadoCita(String id) async => estadoActual;

  @override
  Future<void> updateCitaEstado(String id, EstadoCita nuevoEstado) async {
    estadoEscrito = nuevoEstado;
  }
}

class _LookupFalso implements ConsultaAbiertaLookup {
  final Map<String, ConsultaDeCita> _consultas;

  const _LookupFalso(this._consultas);

  @override
  Future<Map<String, ConsultaDeCita>> paraCitas(List<String> citaIds) async => {
    for (final id in citaIds)
      if (_consultas[id] case final consulta?) id: consulta,
  };

  @override
  Future<bool> tieneConsultaAbierta(String citaId) async =>
      _consultas[citaId]?.estaAbierta ?? false;
}

class _ConsultaRepoFalso extends Fake implements ConsultaRepository {
  final llamadas = <String>[];
  final EstadoInicioConsulta estado;
  final Consulta? detalle;

  /// Consulta que el cubit mandó abrir: es donde se observa que la fecha y la
  /// cita viajan correctas antes de que las resuelva el servidor.
  Consulta? iniciada;

  _ConsultaRepoFalso({
    this.estado = EstadoInicioConsulta.creada,
    this.detalle,
  });

  @override
  Future<InicioConsulta> iniciarConsultaDeCita(Consulta consulta) async {
    iniciada = consulta;
    return InicioConsulta(consultaId: 'consulta-1', estado: estado);
  }

  @override
  Future<Consulta?> getDetalleConsulta(String id) async => detalle;

  @override
  Future<List<Consulta>> getConsultasByDoctor(String doctorId) async {
    llamadas.add('getConsultasByDoctor:$doctorId');
    return const [];
  }

  @override
  Future<Map<String, ConsultaDeCita>> getConsultasPorCitaIds(
    List<String> citaIds,
  ) async => const {};
}

// Colaboradores que `iniciar` no llega a usar en estos casos.

class _StorageNoUsado extends Fake implements SupabaseStorageHelper {}

