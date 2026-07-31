import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/condicion_detectada.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/supabase_storage_helper.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/insumo_utilizado.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_borrador_consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_cierre_consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/crear_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';

class _Vacio {
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} no se usa aquí');
}

class _StorageDoble extends _Vacio implements SupabaseStorageHelper {}

class _CitaRepoDoble extends _Vacio implements CitaRepository {}

class _ConsultaRepoDoble extends _Vacio implements ConsultaRepository {
  _ConsultaRepoDoble({required this.consulta});

  final Consulta consulta;

  int guardados = 0;
  int cierres = 0;
  int cierresFinancieros = 0;
  Odontograma? ultimoOdontograma;
  int? ultimaVersionEnviada;
  final List<String> clavesCierre = [];
  ResultadoBorradorConsulta idsADevolver = const ResultadoBorradorConsulta();
  bool falla = false;
  Object? fallaGuardado;
  Object? fallaCierre;

  @override
  Future<Consulta?> getDetalleConsulta(String id) async => consulta;

  @override
  Future<ResultadoBorradorConsulta> guardarBorradorConsulta({
    required String consultaId,
    int? version,
    required Odontograma odontograma,
    required List<Receta> recetas,
    List<InsumoUtilizado> insumos = const [],
    String? notas,
    SignosVitales? signosVitales,
    List<CondicionDetectada> condicionesDetectadas = const [],
    List<TratamientoAplicado> tratamientosGenerales = const [],
    List<DiagnosticoAplicado> diagnosticosGenerales = const [],
  }) async {
    guardados++;
    ultimoOdontograma = odontograma;
    ultimaVersionEnviada = version;
    final fallo = fallaGuardado;
    if (fallo != null) throw fallo;
    if (falla) throw Exception('sin red');
    return idsADevolver;
  }

  @override
  Future<ResultadoCierreConsulta> cerrarConsulta({
    required String consultaId,
    int? version,
    required Odontograma odontograma,
    required List<Receta> recetas,
    List<InsumoUtilizado> insumos = const [],
    String? notas,
    SignosVitales? signosVitales,
    List<CondicionDetectada> condicionesDetectadas = const [],
    List<TratamientoAplicado> tratamientosGenerales = const [],
    List<DiagnosticoAplicado> diagnosticosGenerales = const [],
    required String idempotenciaKey,
    String? nota,
  }) async {
    cierres++;
    clavesCierre.add(idempotenciaKey);
    final fallo = fallaCierre;
    if (fallo != null) throw fallo;

    // El servidor solo factura lo ejecutado: una evaluación sin tratamientos
    // cierra sin pre-factura.
    final factura = odontograma.dientes.any((d) => d.tratamientos.isNotEmpty);
    if (factura) cierresFinancieros++;
    return ResultadoCierreConsulta(
      consultaId: consultaId,
      cuentaId: factura ? 'cuenta-1' : null,
      montoTotal: factura ? 2500 : 0,
    );
  }
}

Consulta _consultaEnCurso({bool finalizada = false}) => Consulta(
  id: 'c-1',
  pacienteId: 'p-1',
  doctorId: 'd-1',
  fecha: DateTime(2026, 7, 24),
  finalizada: finalizada,
  odontograma: Odontograma(
    consultaId: 'c-1',
    dientes: [Diente(odontogramaId: 'o-1', fdiCode: 16, superficies: const [])],
  ),
);

ConsultaCubit _cubitCon(_ConsultaRepoDoble repo) => ConsultaCubit(
  CrearConsultaUseCase(repo),
  _StorageDoble(),
  _CitaRepoDoble(),
  repo,
);

final _resina = Tratamiento(
  id: 't-1',
  nombre: 'Resina compuesta',
  descripcion: '',
  costo: 2500,
  alcance: Alcance.puntual,
  contraindicaciones: const [],
);

void main() {
  group('autoguardado de la consulta', () {
    test('guardar dos veces sin tocar nada sólo escribe una', () async {
      final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso());
      final cubit = _cubitCon(repo);
      addTearDown(cubit.close);
      await cubit.reanudarConsulta(consultaId: 'c-1');
      final diente = (cubit.state as ConsultaIniciada)
          .consulta
          .odontograma!
          .dientes
          .single;
      cubit.aplicarTratamiento(diente, TipoSuperficie.oclusal, _resina);

      await cubit.guardarParcial();
      expect(repo.guardados, 1);

      // El segundo guardado no tiene nada que llevar: el viaje sobra y, del
      // otro lado, reescribiría las 32 piezas con lo mismo.
      await cubit.guardarParcial();
      expect(repo.guardados, 1);
      expect((cubit.state as ConsultaIniciada).guardado, EstadoGuardado.alDia);

      // Y en cuanto se toca algo, vuelve a salir.
      cubit.aplicarTratamiento(diente, TipoSuperficie.mesial, _resina);
      await cubit.guardarParcial();
      expect(repo.guardados, 2);
    });

    test(
      'una ejecución agregada durante la consulta no exige justificación',
      () async {
        final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso());
        final cubit = _cubitCon(repo);
        addTearDown(cubit.close);
        await cubit.reanudarConsulta(consultaId: 'c-1');
        final diente = (cubit.state as ConsultaIniciada)
            .consulta
            .odontograma!
            .dientes
            .single;

        cubit.aplicarTratamiento(diente, TipoSuperficie.oclusal, _resina);

        final aplicado = (cubit.state as ConsultaIniciada)
            .consulta
            .odontograma!
            .dientes
            .single
            .tratamientos
            .single;
        expect(aplicado.itemPlanId, isNull);
        expect(aplicado.justificacionNoPlanificada, isNull);
      },
    );

    test(
      'una ejecución planificada conserva el vínculo con su actividad',
      () async {
        final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso());
        final cubit = _cubitCon(repo);
        addTearDown(cubit.close);
        await cubit.reanudarConsulta(consultaId: 'c-1');
        final diente = (cubit.state as ConsultaIniciada)
            .consulta
            .odontograma!
            .dientes
            .single;

        cubit.aplicarTratamiento(
          diente,
          TipoSuperficie.oclusal,
          _resina,
          itemPlanId: 'item-plan-1',
        );

        final aplicado = (cubit.state as ConsultaIniciada)
            .consulta
            .odontograma!
            .dientes
            .single
            .tratamientos
            .single;
        expect(aplicado.itemPlanId, 'item-plan-1');
        expect(aplicado.justificacionNoPlanificada, isNull);
      },
    );

    test('terminar sin tratamientos cierra sin generar cuenta', () async {
      final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso());
      final cubit = _cubitCon(repo);
      addTearDown(cubit.close);
      await cubit.reanudarConsulta(consultaId: 'c-1');

      await cubit.terminarAtencion();

      expect(repo.cierres, 1, reason: 'el cierre es una sola operación');
      expect(repo.cierresFinancieros, 0);
      expect(cubit.state, isA<ConsultaTerminada>());
      expect((cubit.state as ConsultaTerminada).cuentaId, isNull);
    });

    test('terminar con tratamientos realiza el cierre financiero', () async {
      final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso());
      final cubit = _cubitCon(repo);
      addTearDown(cubit.close);
      await cubit.reanudarConsulta(consultaId: 'c-1');
      final diente = (cubit.state as ConsultaIniciada)
          .consulta
          .odontograma!
          .dientes
          .single;
      cubit.aplicarTratamiento(diente, TipoSuperficie.oclusal, _resina);

      await cubit.terminarAtencion();

      expect(repo.cierres, 1);
      expect(repo.cierresFinancieros, 1);
      expect((cubit.state as ConsultaTerminada).cuentaId, 'cuenta-1');
    });

    test('un cambio queda pendiente y se guarda solo', () async {
      final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso());
      final cubit = _cubitCon(repo);
      addTearDown(cubit.close);
      await cubit.reanudarConsulta(consultaId: 'c-1');

      final diente = (cubit.state as ConsultaIniciada)
          .consulta
          .odontograma!
          .dientes
          .single;
      cubit.aplicarTratamiento(
        diente,
        TipoSuperficie.oclusal,
        _resina,
        justificacionNoPlanificada: 'Urgencia clínica',
      );

      // Sin tocar nada más: el trabajo aún no está a salvo y se avisa.
      expect(
        (cubit.state as ConsultaIniciada).guardado,
        EstadoGuardado.pendiente,
      );
      expect(repo.guardados, 0);

      await Future<void>.delayed(
        ConsultaCubit.esperaAutoguardado + const Duration(milliseconds: 200),
      );

      expect(repo.guardados, 1);
      expect((cubit.state as ConsultaIniciada).guardado, EstadoGuardado.alDia);
      expect(repo.ultimoOdontograma!.dientes.single.tratamientos, hasLength(1));
    });

    test('los ids que devuelve la BD se sellan sobre el estado', () async {
      final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso())
        ..idsADevolver = const ResultadoBorradorConsulta(
          version: 7,
          tratamientosPorFdi: {
            16: ['ta-1'],
          },
        );
      final cubit = _cubitCon(repo);
      addTearDown(cubit.close);
      await cubit.reanudarConsulta(consultaId: 'c-1');

      final diente = (cubit.state as ConsultaIniciada)
          .consulta
          .odontograma!
          .dientes
          .single;
      cubit.aplicarTratamiento(
        diente,
        TipoSuperficie.oclusal,
        _resina,
        justificacionNoPlanificada: 'Urgencia clínica',
      );
      await cubit.guardarParcial();

      final tratamiento = (cubit.state as ConsultaIniciada)
          .consulta
          .odontograma!
          .dientes
          .single
          .tratamientos
          .single;
      // Con el id sellado, el siguiente guardado actualiza esa fila en vez de
      // insertar un duplicado.
      expect(tratamiento.id, 'ta-1');
    });

    test(
      'si el guardado falla, el trabajo sigue en memoria y se avisa',
      () async {
        final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso())
          ..falla = true;
        final cubit = _cubitCon(repo);
        addTearDown(cubit.close);
        await cubit.reanudarConsulta(consultaId: 'c-1');

        final diente = (cubit.state as ConsultaIniciada)
            .consulta
            .odontograma!
            .dientes
            .single;
        cubit.aplicarTratamiento(
          diente,
          TipoSuperficie.oclusal,
          _resina,
          justificacionNoPlanificada: 'Urgencia clínica',
        );
        await cubit.guardarParcial();

        final estado = cubit.state as ConsultaIniciada;
        expect(estado.guardado, EstadoGuardado.fallido);
        // Lo importante: no se perdió nada y el doctor sigue en su consulta.
        expect(
          estado.consulta.odontograma!.dientes.single.tratamientos,
          hasLength(1),
        );

        await Future<void>.delayed(
          ConsultaCubit.esperaAutoguardado + const Duration(milliseconds: 200),
        );
        expect(
          repo.guardados,
          1,
          reason: 'un fallo permanente no debe generar reintentos infinitos',
        );
      },
    );

    test(
      'la versión confirmada viaja en el siguiente guardado',
      () async {
        final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso())
          ..idsADevolver = const ResultadoBorradorConsulta(version: 7);
        final cubit = _cubitCon(repo);
        addTearDown(cubit.close);
        await cubit.reanudarConsulta(consultaId: 'c-1');

        final diente = (cubit.state as ConsultaIniciada)
            .consulta
            .odontograma!
            .dientes
            .single;
        cubit.aplicarTratamiento(diente, TipoSuperficie.oclusal, _resina);
        await cubit.guardarParcial();

        cubit.aplicarTratamiento(diente, TipoSuperficie.mesial, _resina);
        await cubit.guardarParcial();

        // Sin esto, dos pestañas se sobrescriben en silencio: la segunda
        // escritura siempre parecería estar al día.
        expect(repo.ultimaVersionEnviada, 7);
      },
    );

    test(
      'un conflicto de versión se distingue de un fallo de red y explica qué hacer',
      () async {
        final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso())
          ..fallaGuardado = const ConflictoVersionFailure();
        final cubit = _cubitCon(repo);
        addTearDown(cubit.close);
        await cubit.reanudarConsulta(consultaId: 'c-1');

        final diente = (cubit.state as ConsultaIniciada)
            .consulta
            .odontograma!
            .dientes
            .single;
        cubit.aplicarTratamiento(diente, TipoSuperficie.oclusal, _resina);
        await cubit.guardarParcial();

        final estado = cubit.state as ConsultaIniciada;
        expect(estado.guardado, EstadoGuardado.conflicto);
        expect(estado.detalleFallo, contains('Recarga'));
        // El trabajo local no se descarta por un conflicto.
        expect(
          estado.consulta.odontograma!.dientes.single.tratamientos,
          hasLength(1),
        );
      },
    );

    test(
      'reintentar un cierre fallido conserva la misma clave de idempotencia',
      () async {
        final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso())
          ..fallaCierre = const NetworkFailure();
        final cubit = _cubitCon(repo);
        addTearDown(cubit.close);
        await cubit.reanudarConsulta(consultaId: 'c-1');
        final diente = (cubit.state as ConsultaIniciada)
            .consulta
            .odontograma!
            .dientes
            .single;
        cubit.aplicarTratamiento(diente, TipoSuperficie.oclusal, _resina);

        await cubit.terminarConsulta();
        expect(cubit.state, isA<ConsultaIniciada>());

        repo.fallaCierre = null;
        await cubit.terminarConsulta();

        // Si la primera respuesta se perdió por red, el servidor tiene que
        // reconocer el reintento como el mismo intento y no cobrar dos veces.
        expect(repo.clavesCierre, hasLength(2));
        expect(repo.clavesCierre.first, repo.clavesCierre.last);
        expect((cubit.state as ConsultaTerminada).cuentaId, 'cuenta-1');
      },
    );

    test('un cierre fallido explica que nada quedó a medias', () async {
      final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso())
        ..fallaCierre = const StockInsuficienteFailure(
          'Stock insuficiente de Gasas: quedan 1 y la consulta consume 3.',
        );
      final cubit = _cubitCon(repo);
      addTearDown(cubit.close);
      await cubit.reanudarConsulta(consultaId: 'c-1');
      final diente = (cubit.state as ConsultaIniciada)
          .consulta
          .odontograma!
          .dientes
          .single;
      cubit.aplicarTratamiento(diente, TipoSuperficie.oclusal, _resina);

      // Desde HFX-CLIN-005 el fallo no viaja como un estado de paso que la
      // pantalla convertía en un snackbar de tres segundos: la consulta vuelve
      // abierta y el motivo se queda dentro de su propio estado.
      final esperado = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ConsultaGuardando>(),
          isA<ConsultaIniciada>()
              .having(
                (e) => e.guardado,
                'guardado',
                EstadoGuardado.fallido,
              )
              .having(
                (e) => e.detalleFallo,
                'detalle',
                allOf(contains('Gasas'), contains('consume 3')),
              ),
        ]),
      );
      await cubit.terminarConsulta();
      await esperado;

      // El doctor vuelve a su consulta, que sigue abierta, y el chip no dice
      // "Guardado" después de que el cierre se cayera.
      final vigente = cubit.state as ConsultaIniciada;
      expect(vigente.guardado, EstadoGuardado.fallido);
    });

    test('el cierre confirmado saca al doctor del workspace', () async {
      final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso());
      final cubit = _cubitCon(repo);
      addTearDown(cubit.close);
      await cubit.reanudarConsulta(consultaId: 'c-1');
      final diente = (cubit.state as ConsultaIniciada)
          .consulta
          .odontograma!
          .dientes
          .single;
      cubit.aplicarTratamiento(diente, TipoSuperficie.oclusal, _resina);

      await cubit.terminarConsulta();

      final terminada = cubit.state as ConsultaTerminada;
      expect(terminada.consultaId, 'c-1');
      expect(terminada.montoTotal, 2500);
    });

    test(
      'guardar sobre una consulta ya cerrada saca del workspace, no reintenta',
      () async {
        final repo = _ConsultaRepoDoble(consulta: _consultaEnCurso())
          ..fallaGuardado = const ConsultaCerradaFailure();
        final cubit = _cubitCon(repo);
        addTearDown(cubit.close);
        await cubit.reanudarConsulta(consultaId: 'c-1');
        final diente = (cubit.state as ConsultaIniciada)
            .consulta
            .odontograma!
            .dientes
            .single;
        cubit.aplicarTratamiento(diente, TipoSuperficie.oclusal, _resina);

        await cubit.guardarParcial();

        // Seguir editando un expediente cerrado es la ficción que este ticket
        // elimina: la pantalla tiene que decirlo, no autoguardar en el vacío.
        // No es un error cualquiera —no hay nada que reintentar—, así que
        // desde HFX-CLIN-005 tiene su propio estado terminal.
        expect(cubit.state, isA<ConsultaCerradaEnServidor>());
        final cerrada = cubit.state as ConsultaCerradaEnServidor;
        expect(cerrada.mensaje, contains('ya fue finalizada'));
        expect(cerrada.consultaId, 'c-1');
      },
    );

    test('una consulta ya finalizada no se puede reanudar', () async {
      final repo = _ConsultaRepoDoble(
        consulta: _consultaEnCurso(finalizada: true),
      );
      final cubit = _cubitCon(repo);
      addTearDown(cubit.close);

      await cubit.reanudarConsulta(consultaId: 'c-1');

      expect(cubit.state, isA<ConsultaError>());
      expect(
        (cubit.state as ConsultaError).message,
        contains('ya fue finalizada'),
      );
    });
  });
}
