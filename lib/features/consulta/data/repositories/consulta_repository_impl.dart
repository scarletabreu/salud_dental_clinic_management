import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/core/util/app_log.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/models/consulta_model.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta_de_cita.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/insumo_utilizado.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_borrador_consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_cierre_consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/tratamiento_aplicado_detalle.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/models/diagnostico_aplicado_model.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/data/models/item_plan_tratamiento_model.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/item_receta_model.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/models/tratamiento_aplicado_model.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

class ConsultaRepositoryImpl implements ConsultaRepository {
  final ConsultaRemoteDatasource remoteDataSource;

  ConsultaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Consulta>> getConsultas() {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchConsultas();
      return _parsearConsultas(data);
    }, context: 'obtener las consultas');
  }

  @override
  Future<List<Consulta>> getConsultasByDoctor(String doctorId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchConsultasByDoctor(doctorId);
      return _parsearConsultas(data);
    }, context: 'obtener las consultas');
  }

  @override
  Future<Map<String, ConsultaDeCita>> getConsultasPorCitaIds(
    List<String> citaIds,
  ) {
    return runGuarded(() async {
      final filas = await remoteDataSource.fetchConsultasPorCitaIds(citaIds);
      final porCita = <String, ConsultaDeCita>{};
      for (final fila in filas) {
        final citaId = fila['cita_id'] as String?;
        final id = fila['id'] as String?;
        if (citaId == null || id == null) continue;
        final referencia = ConsultaDeCita(
          id: id,
          finalizada: (fila['finalizada'] ?? false) as bool,
        );
        // Con varias consultas por cita (dato inconsistente) prevalece la
        // abierta: es la que impide cancelar y la que conviene abrir.
        final previa = porCita[citaId];
        if (previa == null || (previa.finalizada && referencia.estaAbierta)) {
          porCita[citaId] = referencia;
        }
      }
      return porCita;
    }, context: 'obtener las consultas de las citas');
  }

  /// Una fila que no se puede leer se registra y se omite, en vez de abortar
  /// todo el listado. Un `.map()` directo convertía cualquier fila con una
  /// forma inesperada en una pantalla de error sin detalle para el usuario y
  /// sin rastro para nosotros: se perdían las 37 consultas legibles por culpa
  /// de la 38.ª. El fallo sigue siendo visible en el log, no se silencia.
  List<Consulta> _parsearConsultas(List<Map<String, dynamic>> filas) {
    final consultas = <Consulta>[];
    for (final fila in filas) {
      try {
        consultas.add(ConsultaModel.fromJson(fila));
      } catch (e, stack) {
        AppLog.error('parsear la consulta ${fila['id']}', e, stack);
      }
    }
    return consultas;
  }

  bool _isValidUuid(String? id) =>
      id != null && id.length == 36 && id.contains('-');

  @override
  Future<String> crearConsultaCompleta(Consulta consulta) {
    if (!_isValidUuid(consulta.pacienteId)) {
      throw Exception(
        'No se puede crear una consulta para un paciente de prueba. '
        'Registra un paciente real en el sistema.',
      );
    }
    return runGuarded(() async {
      final dientes = (consulta.odontograma?.dientes ?? [])
          .map(
            (d) => {
              'fdi_code': d.fdiCode,
              'superficies': d.superficies
                  .map((s) => s.tipoSuperficie.name)
                  .toList(),
            },
          )
          .toList();

      final documentos = consulta.documentosClinicos
          .map(
            (doc) => {
              'descripcion': doc.descripcion,
              'tipo_documento': doc.tipoDocumento.name,
              'url_archivo': doc.urlArchivo,
              'fecha_creacion': doc.fechaCreacion.toUtc().toIso8601String(),
            },
          )
          .toList();

      final params = {
        'p_paciente_id': consulta.pacienteId,
        'p_doctor_id': consulta.doctorId,
        'p_cita_id': consulta.citaId,
        'p_fecha': consulta.fecha.toUtc().toIso8601String(),
        'p_motivo_consulta': consulta.motivoConsulta,
        'p_temp_condiciones': consulta.tempCondiciones,
        'p_dientes': dientes,
        'p_documentos': documentos,
        'p_tipo_atencion': consulta.tipoAtencion.name,
      };

      final id = await remoteDataSource.crearConsultaCompleta(params);
      if (consulta.signosVitales != null &&
          !consulta.signosVitales!.estaVacia) {
        await remoteDataSource.updateConsulta(id, {
          'signos_vitales': consulta.signosVitales!.toJson(),
        });
      }
      return id;
    }, context: 'crear la consulta completa');
  }

  @override
  Future<ResultadoBorradorConsulta> guardarBorradorConsulta({
    required String consultaId,
    int? version,
    required Odontograma odontograma,
    required List<Receta> recetas,
    List<InsumoUtilizado> insumos = const [],
    String? notas,
    Map<String, dynamic>? signosVitales,
  }) {
    return runGuarded(() async {
      final respuesta = await remoteDataSource.guardarBorradorConsulta(
        consultaId: consultaId,
        version: version,
        payload: _payloadClinico(
          odontograma: odontograma,
          recetas: recetas,
          insumos: insumos,
          notas: notas,
          signosVitales: signosVitales,
        ),
      );
      return ResultadoBorradorConsulta.fromRpc(respuesta);
    }, context: 'guardar el resultado de la consulta');
  }

  @override
  Future<ResultadoCierreConsulta> cerrarConsulta({
    required String consultaId,
    int? version,
    required Odontograma odontograma,
    required List<Receta> recetas,
    List<InsumoUtilizado> insumos = const [],
    String? notas,
    Map<String, dynamic>? signosVitales,
    required String idempotenciaKey,
    String? nota,
  }) {
    return runGuarded(() async {
      final respuesta = await remoteDataSource.cerrarConsulta(
        consultaId: consultaId,
        version: version,
        payload: _payloadClinico(
          odontograma: odontograma,
          recetas: recetas,
          insumos: insumos,
          notas: notas,
          signosVitales: signosVitales,
        ),
        idempotenciaKey: idempotenciaKey,
        nota: nota,
      );
      return ResultadoCierreConsulta.fromRpc(respuesta);
    }, context: 'cerrar la consulta');
  }

  /// Contrato versionado que entienden `guardar_borrador_consulta` y
  /// `cerrar_consulta`. Una clave presente describe el conjunto completo
  /// deseado; lo que falte en ella se anula del lado del servidor.
  Map<String, dynamic> _payloadClinico({
    required Odontograma odontograma,
    required List<Receta> recetas,
    required List<InsumoUtilizado> insumos,
    String? notas,
    Map<String, dynamic>? signosVitales,
  }) {
    final dientes = [
      for (final diente in odontograma.dientes)
        {
          'fdi_code': diente.fdiCode,
          'esta_ausente': diente.estaAusente,
          'observaciones': diente.observaciones,
          'tratamientos': [
            for (final t in diente.tratamientos)
              {
                if (t.id != null) 'id': t.id,
                'tratamiento_id': t.tratamientoId,
                'es_continuo': t.esContinuo,
                'esta_terminado': t.estaTerminado,
                'superficie': t.superficie?.name.toLowerCase(),
                'precio_aplicado': t.precioAplicado,
                'notas': t.notas,
                'estado': t.estado.dbValue,
                'item_plan_id': t.itemPlanId,
                'justificacion_no_planificada': t.justificacionNoPlanificada,
                'doctor_ejecuta_id': t.doctorEjecutaId,
                'fecha_ejecucion': (t.fechaEjecucion ?? t.fechaAplicacion)
                    ?.toUtc()
                    .toIso8601String(),
              },
          ],
          'diagnosticos': [
            for (final diagnostico in diente.diagnosis)
              {
                if (diagnostico.id != null) 'id': diagnostico.id,
                'diagnosis_id': diagnostico.diagnosisId,
                'severidad': diagnostico.severidad.name,
                'fecha_aplicacion': diagnostico.fechaAplicacion
                    .toUtc()
                    .toIso8601String(),
                'superficie': diagnostico.superficie?.name.toLowerCase(),
                'origen': diagnostico.origen.name,
                'notas': diagnostico.notas,
              },
          ],
        },
    ];

    return {
      'version_payload': 1,
      if (notas != null) 'notas': notas,
      if (signosVitales != null) 'signos_vitales': signosVitales,
      'evaluacion_clinica': odontograma.evaluacionToJson(),
      'dientes': dientes,
      'recetas': [
        for (final r in recetas)
          {
            ...RecetaModel.fromEntity(r).toCabeceraJson(),
            'items_receta': [
              for (final item in r.items)
                ItemRecetaModel.fromEntity(item).toJson(recetaId: r.id ?? ''),
            ],
          },
      ],
      'insumos': [for (final insumo in insumos) insumo.toJson()],
    };
  }

  @override
  Future<Map<String, TratamientoAplicadoDetalle>>
  getDetalleTratamientosAplicados(List<String> ids) {
    return runGuarded(() async {
      final filas = await remoteDataSource.fetchTratamientosAplicadosPorIds(
        ids,
      );
      return {
        for (final fila in filas)
          if (fila['id'] != null)
            fila['id'] as String: TratamientoAplicadoDetalle(
              nombre:
                  (fila['tratamiento']?['nombre'] as String?) ?? 'Tratamiento',
              tratamiento: TratamientoAplicadoModel.fromJson(fila),
            ),
      };
    }, context: 'obtener los tratamientos aplicados');
  }

  @override
  Future<List<Consulta>> getHistorialPaciente(String pacienteId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchConsultasByPaciente(pacienteId);
      return data.map((json) => ConsultaModel.fromJson(json)).toList();
    }, context: 'obtener el historial clínico');
  }

  @override
  Future<Map<int, List<TratamientoAplicado>>>
  getTratamientosHistoricosPorDiente(
    String pacienteId, {
    String? excluyendoConsultaId,
  }) {
    return runGuarded(() async {
      final filas = await remoteDataSource.fetchTratamientosHistoricosPaciente(
        pacienteId,
        excluyendoConsultaId: excluyendoConsultaId,
      );

      final porFdi = <int, List<TratamientoAplicado>>{};
      for (final fila in filas) {
        final fdi = (fila['diente']?['fdi_code'] as num?)?.toInt();
        if (fdi == null) continue;
        porFdi
            .putIfAbsent(fdi, () => [])
            .add(TratamientoAplicadoModel.fromJson(fila));
      }
      return porFdi;
    }, context: 'obtener los tratamientos históricos');
  }

  @override
  Future<Map<int, List<DiagnosticoAplicado>>>
  getDiagnosticosHistoricosPorDiente(
    String pacienteId, {
    String? excluyendoConsultaId,
  }) {
    return runGuarded(() async {
      final filas = await remoteDataSource.fetchDiagnosticosHistoricosPaciente(
        pacienteId,
        excluyendoConsultaId: excluyendoConsultaId,
      );

      final porFdi = <int, List<DiagnosticoAplicado>>{};
      for (final fila in filas) {
        final fdi = (fila['diente']?['fdi_code'] as num?)?.toInt();
        if (fdi == null) continue;
        porFdi
            .putIfAbsent(fdi, () => [])
            .add(DiagnosticoAplicadoModel.fromJson(fila));
      }
      return porFdi;
    }, context: 'obtener los hallazgos anteriores');
  }

  @override
  Future<HistorialPiezas> getHistorialPiezas(String pacienteId) {
    return runGuarded(() async {
      final (filasDiagnosticos, filasTratamientos, filasConsultas) = await (
        remoteDataSource.fetchDiagnosticosHistoricosPaciente(
          pacienteId,
          incluyendoAnulados: true,
        ),
        remoteDataSource.fetchTratamientosHistoricosPaciente(
          pacienteId,
          incluyendoAnulados: true,
        ),
        remoteDataSource.fetchReferenciasConsultasPaciente(pacienteId),
      ).wait;

      var filasItemsPlan = const <Map<String, dynamic>>[];
      try {
        filasItemsPlan = await remoteDataSource.fetchItemsPlanPorPaciente(
          pacienteId,
        );
      } catch (e) {
        AppLog.error('plan del historial de piezas', e);
      }

      final diagnosticos = <int, List<DiagnosticoAplicado>>{};
      for (final fila in filasDiagnosticos) {
        final fdi = (fila['diente']?['fdi_code'] as num?)?.toInt();
        if (fdi == null) continue;
        diagnosticos
            .putIfAbsent(fdi, () => [])
            .add(DiagnosticoAplicadoModel.fromJson(fila));
      }

      final tratamientos = <int, List<TratamientoAplicado>>{};
      for (final fila in filasTratamientos) {
        final fdi = (fila['diente']?['fdi_code'] as num?)?.toInt();
        if (fdi == null) continue;
        tratamientos
            .putIfAbsent(fdi, () => [])
            .add(TratamientoAplicadoModel.fromJson(fila));
      }

      final itemsPlan = <int, List<ItemPlanTratamiento>>{};
      for (final fila in filasItemsPlan) {
        final item = ItemPlanTratamientoModel.fromJson(fila);
        final fdi = item.fdiDiente;
        if (fdi == null) continue;
        itemsPlan.putIfAbsent(fdi, () => []).add(item);
      }

      final consultas = {
        for (final fila in filasConsultas)
          if (fila['id'] case final String id)
            id: ReferenciaConsulta(
              id: id,
              fecha:
                  DateTime.tryParse(fila['fecha']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
              motivo: fila['motivo_consulta'] as String?,
              tipoAtencion: TipoAtencionClinica.fromDb(
                fila['tipo_atencion'] as String?,
              ),
              doctorId: fila['doctor_id'] as String?,
            ),
      };

      final historial = HistorialPiezas.consolidar(
        diagnosticos: diagnosticos,
        tratamientos: tratamientos,
        itemsPlan: itemsPlan,
        consultas: consultas,
        nombrePorDoctorId: await _nombresDeDoctoresDe(
          diagnosticos,
          tratamientos,
          itemsPlan,
          consultas,
        ),
      );
      return historial;
    }, context: 'obtener el historial de las piezas');
  }

  Future<Map<String, String>> _nombresDeDoctoresDe(
    Map<int, List<DiagnosticoAplicado>> diagnosticos,
    Map<int, List<TratamientoAplicado>> tratamientos,
    Map<int, List<ItemPlanTratamiento>> itemsPlan,
    Map<String, ReferenciaConsulta> consultas,
  ) async {
    final ids = <String>{
      for (final filas in diagnosticos.values)
        for (final fila in filas) ?fila.doctorId,
      for (final filas in tratamientos.values)
        for (final fila in filas) ?fila.doctorEjecutaId,
      for (final filas in itemsPlan.values)
        for (final fila in filas) ?fila.doctorProponeId,
      for (final consulta in consultas.values) ?consulta.doctorId,
    };
    if (ids.isEmpty) return const {};

    try {
      final filas = await remoteDataSource.fetchNombresDoctores(ids.toList());
      return {
        for (final fila in filas)
          if (fila['id'] case final String id)
            if (_nombreDeDoctor(fila) case final nombre when nombre.isNotEmpty)
              id: nombre,
      };
    } catch (e) {
      AppLog.error('nombres de doctores del historial', e);
      return const {};
    }
  }

  static String _nombreDeDoctor(Map<String, dynamic> fila) {
    final usuario = fila['usuarios'];
    final persona = usuario is Map ? usuario['personas'] : null;
    if (persona is! Map) return '';
    final nombre = (persona['nombre'] as String? ?? '').trim();
    final apellido = (persona['apellido'] as String? ?? '').trim();
    final completo = '$nombre $apellido'.trim();
    return completo.isEmpty ? '' : 'Dr. $completo';
  }

  @override
  Future<EvaluacionOdontologica> getEvaluacionHistorica(
    String pacienteId, {
    String? excluyendoConsultaId,
  }) {
    return runGuarded(() async {
      final diagnosticos = await remoteDataSource
          .fetchDiagnosticosHistoricosPaciente(
            pacienteId,
            excluyendoConsultaId: excluyendoConsultaId,
          );

      final consultaQueMandaPorFdi = <int, String?>{};
      final porFdi = <int, Map<EstadoClinicoDental, Set<TipoSuperficie>>>{};

      for (final fila in diagnosticos) {
        final fdi = (fila['diente']?['fdi_code'] as num?)?.toInt();
        if (fdi == null) continue;
        final diagnostico = DiagnosticoAplicadoModel.fromJson(fila);
        final estado = EstadoClinicoDentalX.fromDb(
          diagnostico.claveOdontograma,
        );
        if (estado == null) continue;

        final consultaQueManda = consultaQueMandaPorFdi.putIfAbsent(
          fdi,
          () => diagnostico.consultaId,
        );
        if (diagnostico.consultaId != consultaQueManda) continue;

        final caras = porFdi
            .putIfAbsent(fdi, () => {})
            .putIfAbsent(estado, () => <TipoSuperficie>{});
        final superficie = diagnostico.superficie;
        if (superficie != null && estado.esPorSuperficie) caras.add(superficie);
      }

      final evaluaciones = await remoteDataSource.fetchEvaluacionesPaciente(
        pacienteId,
        excluyendoConsultaId: excluyendoConsultaId,
      );
      final tejidos = EvaluacionOdontologica.consolidar(
        evaluaciones.map(
          (f) => EvaluacionOdontologica.fromJson(f['evaluacion_clinica']),
        ),
      ).tejidosBlandos;

      return EvaluacionOdontologica(
        hallazgos: {
          for (final entry in porFdi.entries)
            entry.key: [
              for (final hallazgo in entry.value.entries)
                HallazgoDental(
                  estado: hallazgo.key,
                  superficies: hallazgo.value,
                ),
            ],
        },
        tejidosBlandos: tejidos,
      );
    }, context: 'obtener el odontodiagrama histórico');
  }

  @override
  Future<Consulta?> getDetalleConsulta(String id) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchConsultaById(id);
      return data != null ? ConsultaModel.fromJson(data) : null;
    }, context: 'obtener el detalle de la consulta');
  }

  @override
  Future<void> eliminarConsulta(String id) {
    return runGuarded(
      () => remoteDataSource.deleteConsulta(id),
      context: 'eliminar la consulta',
    );
  }
}
