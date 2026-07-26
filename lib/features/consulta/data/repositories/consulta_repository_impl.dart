import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/tratamiento_aplicado_detalle.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_guardado_odontograma.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/models/consulta_model.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/models/diagnostico_aplicado_model.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';
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
      return data.map((json) => ConsultaModel.fromJson(json)).toList();
    }, context: 'obtener las consultas');
  }

  @override
  Future<List<Consulta>> getConsultasByDoctor(String doctorId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchConsultasByDoctor(doctorId);
      return data.map((json) => ConsultaModel.fromJson(json)).toList();
    }, context: 'obtener las consultas');
  }

  bool _isValidUuid(String? id) =>
      id != null && id.length == 36 && id.contains('-');

  @override
  Future<String> crearConsultaCompleta(Consulta consulta) {
    // Validación de dominio fuera del guard: el cubit detecta este mensaje
    // ('paciente de prueba') como caso especial.
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
  Future<String> finalizarConsulta({required String consultaId, String? nota}) {
    return runGuarded(
      () => remoteDataSource.finalizarConsulta(
        consultaId: consultaId,
        nota: nota,
      ),
      context: 'finalizar la consulta',
    );
  }

  @override
  Future<ResultadoGuardadoOdontograma> guardarResultadoConsulta({
    required String consultaId,
    required String? pacienteId,
    required Odontograma odontograma,
    required List<Receta> recetas,
    String? notas,
    Map<String, dynamic>? signosVitales,
    bool? finalizada,
  }) {
    return runGuarded(() async {
      final dientesPorFdi = <int, Map<String, dynamic>>{
        for (final diente in odontograma.dientes)
          diente.fdiCode: {
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
                  'aprecio_aplicado': t.precioAplicado,
                  // La justificación clínica de una contraindicación viaja
                  // aquí. Sin ella el expediente diría que el tratamiento se
                  // aplicó a ciegas.
                  'notas': t.notas,
                  'estado': t.estado.dbValue,
                  // Auditoría de la ejecución (SD-135). `item_plan_id` solo
                  // viaja cuando la ejecución cumple una actividad ya decidida
                  // del plan; la base rechaza vincularla a una propuesta.
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
      };

      final recetasJson = [
        for (final r in recetas) RecetaModel.fromEntity(r).toJson(),
      ];

      return remoteDataSource.guardarResultadoConsulta(
        consultaId: consultaId,
        pacienteId: pacienteId,
        dientesPorFdi: dientesPorFdi,
        recetas: recetasJson,
        evaluacionOdontologica: odontograma.evaluacionToJson(),
        notas: notas,
        signosVitales: signosVitales,
        finalizada: finalizada,
      );
    }, context: 'guardar el resultado de la consulta');
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
  Future<EvaluacionOdontologica> getEvaluacionHistorica(
    String pacienteId, {
    String? excluyendoConsultaId,
  }) {
    return runGuarded(() async {
      // Las piezas salen de `diagnosticos_aplicados`: desde SD-150 el jsonb de
      // `odontogramas` solo guarda tejidos blandos. Los tratamientos previos no
      // se dibujan en tenue, se leen en la ficha de la pieza.
      final diagnosticos = await remoteDataSource
          .fetchDiagnosticosHistoricosPaciente(
            pacienteId,
            excluyendoConsultaId: excluyendoConsultaId,
          );

      // Las filas llegan de la consulta más reciente a la más antigua: sobre
      // cada pieza manda la última que la anotó, con todo lo que dijo de ella.
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
