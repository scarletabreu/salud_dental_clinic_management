import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/data/datasources/diagnosis_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/data/models/diagnosis_model.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/categoria_diagnosis.dart';

class DiagnosisRepositoryImpl implements DiagnosisRepository {
  final DiagnosisRemoteDatasource remoteDataSource;

  DiagnosisRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Diagnosis>> getCatalogoCompleto() {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchCatalogoDiagnosis();
      return data.map((json) => DiagnosisModel.fromJson(json)).toList();
    }, context: 'obtener el catálogo de diagnósticos');
  }

  @override
  Future<List<Diagnosis>> getDiagnosisPorCategoria(
    CategoriaDiagnosis categoria,
  ) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchDiagnosisByCategoria(
        categoria.name,
      );
      return data.map((json) => DiagnosisModel.fromJson(json)).toList();
    }, context: 'filtrar los diagnósticos por categoría');
  }

  @override
  Future<void> eliminarDiagnosisDelCatalogo(String id) {
    return runGuarded(
      () => remoteDataSource.deleteDiagnosis(id),
      context: 'eliminar el diagnóstico',
    );
  }
}
