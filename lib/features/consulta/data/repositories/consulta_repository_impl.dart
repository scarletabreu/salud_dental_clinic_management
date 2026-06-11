import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/models/consulta_model.dart';

class ConsultaRepositoryImpl implements ConsultaRepository {
  final ConsultaRemoteDatasource remoteDataSource;

  ConsultaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> registrarConsulta(Consulta consulta) async {
    try {
      final model = ConsultaModel(
        id: consulta.id,
        pacienteId: consulta.pacienteId,
        doctorId: consulta.doctorId,
        citaId: consulta.citaId,
        fecha: consulta.fecha,
        recetas: consulta.recetas,
        documentosClinicos: consulta.documentosClinicos,
        odontograma: consulta.odontograma,
        tempCondiciones: consulta.tempCondiciones,
        motivoConsulta: consulta.motivoConsulta,
      );
      await remoteDataSource.crearConsulta(model);
    } catch (e) {
      throw Exception('Error en el repositorio al registrar consulta: $e');
    }
  }

  @override
  Future<void> crearConsultaCompleta(Consulta consulta) async {
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

      await remoteDataSource.crearConsultaCompleta(params);
    } catch (e) {
      throw Exception('Error en el repositorio al crear consulta completa: $e');
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
