import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/models/consulta_model.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';

class ConsultaRepositoryImpl implements ConsultaRepository {
  final ConsultaRemoteDatasource remoteDataSource;

  ConsultaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Consulta>> getConsultas() async {
    try {
      final data = await remoteDataSource.fetchConsultas();
      return data.map((json) => ConsultaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error en el repositorio al obtener consultas: $e');
    }
  }

  bool _isValidUuid(String? id) =>
      id != null && id.length == 36 && id.contains('-');

  @override
  Future<String> crearConsultaCompleta(Consulta consulta) async {
    if (!_isValidUuid(consulta.pacienteId)) {
      throw Exception(
        'No se puede crear una consulta para un paciente de prueba. '
        'Registra un paciente real en el sistema.',
      );
    }
    try {
      final dientes = (consulta.odontograma?.dientes ?? [])
          .map(
            (d) => {
              'fdi_code': d.fdiCode,
              'superficies':
                  d.superficies.map((s) => s.tipoSuperficie.name).toList(),
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
      };

      return await remoteDataSource.crearConsultaCompleta(params);
    } catch (e) {
      throw Exception('Error en el repositorio al crear consulta completa: $e');
    }
  }

  @override
  Future<void> guardarResultadoConsulta({
    required String consultaId,
    required Odontograma odontograma,
    String? notas,
  }) async {
    try {
      final tratamientosPorFdi = <int, List<Map<String, dynamic>>>{
        for (final diente in odontograma.dientes)
          if (diente.tratamientos.isNotEmpty)
            diente.fdiCode: [
              for (final t in diente.tratamientos)
                {
                  'tratamiento_id': t.tratamientoId,
                  'es_continuo': t.esContinuo,
                  'esta_terminado': t.estaTerminado,
                },
            ],
      };

      await remoteDataSource.guardarResultadoConsulta(
        consultaId: consultaId,
        tratamientosPorFdi: tratamientosPorFdi,
        notas: notas,
      );
    } catch (e) {
      throw Exception(
        'Error en el repositorio al guardar el resultado de la consulta: $e',
      );
    }
  }

  @override
  Future<Map<String, String>> getNombresTratamientosAplicados(
    List<String> ids,
  ) async {
    try {
      final filas = await remoteDataSource.fetchTratamientosAplicadosPorIds(
        ids,
      );
      return {
        for (final fila in filas)
          if (fila['id'] != null)
            fila['id'] as String:
                (fila['tratamiento']?['nombre'] as String?) ?? 'Tratamiento',
      };
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener tratamientos aplicados: $e',
      );
    }
  }

  @override
  Future<List<Consulta>> getHistorialPaciente(String pacienteId) async {
    try {
      final data = await remoteDataSource.fetchConsultasByPaciente(pacienteId);
      return data.map((json) => ConsultaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener historial clínico: $e',
      );
    }
  }

  @override
  Future<Consulta?> getDetalleConsulta(String id) async {
    try {
      final data = await remoteDataSource.fetchConsultaById(id);
      return data != null ? ConsultaModel.fromJson(data) : null;
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener detalle de consulta: $e',
      );
    }
  }

  @override
  Future<void> eliminarConsulta(String id) async {
    try {
      await remoteDataSource.deleteConsulta(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar consulta: $e');
    }
  }
}
