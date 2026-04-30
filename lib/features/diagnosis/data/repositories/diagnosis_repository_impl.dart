import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/data/datasources/diagnosis_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/data/models/diagnosis_model.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/categoria_diagnosis.dart';

class DiagnosisRepositoryImpl implements DiagnosisRepository {
  final DiagnosisRemoteDatasource remoteDataSource;

  DiagnosisRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Diagnosis>> getCatalogoCompleto() async {
    try {
      final data = await remoteDataSource.fetchCatalogoDiagnosis();
      return data.map((json) => DiagnosisModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener catálogo de diagnósticos: $e',
      );
    }
  }

  @override
  Future<List<Diagnosis>> getDiagnosisPorCategoria(
    CategoriaDiagnosis categoria,
  ) async {
    try {
      final data = await remoteDataSource.fetchDiagnosisByCategoria(
        categoria.name,
      );
      return data.map((json) => DiagnosisModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al filtrar diagnósticos por categoría: $e',
      );
    }
  }

  @override
  Future<void> eliminarDiagnosisDelCatalogo(String id) async {
    try {
      await remoteDataSource.deleteDiagnosis(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar diagnóstico: $e');
    }
  }
}
