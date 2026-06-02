import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/repositories/diagnostico_aplicado_repository.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/datasources/diagnostico_aplicado_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/models/diagnostico_aplicado_model.dart';

class DiagnosticoAplicadoRepositoryImpl
    implements DiagnosticoAplicadoRepository {
  final DiagnosticoAplicadoRemoteDatasource remoteDataSource;

  DiagnosticoAplicadoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> aplicarDiagnostico(DiagnosticoAplicado diagnostico) async {
    try {
      final model = DiagnosticoAplicadoModel(
        id: diagnostico.id,
        diagnosisId: diagnostico.diagnosisId,
        severidad: diagnostico.severidad,
        fechaAplicacion: diagnostico.fechaAplicacion,
        notas: diagnostico.notas,
      );
      await remoteDataSource.insertDiagnostico(model.toJson());
    } catch (e) {
      throw Exception('Error en el repositorio al aplicar diagnóstico: $e');
    }
  }

  @override
  Future<List<DiagnosticoAplicado>> getDiagnosticosDeConsulta(
    String consultaId,
  ) async {
    try {
      final data = await remoteDataSource.fetchByConsulta(consultaId);
      return data
          .map((json) => DiagnosticoAplicadoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener diagnósticos de la consulta: $e',
      );
    }
  }

  @override
  Future<void> eliminarDiagnostico(String id) async {
    try {
      await remoteDataSource.deleteDiagnostico(id);
    } catch (e) {
      throw Exception(
        'Error en el repositorio al eliminar diagnóstico aplicado: $e',
      );
    }
  }
}
