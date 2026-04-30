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
