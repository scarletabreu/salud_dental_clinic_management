import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/data/datasources/diagnosis_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/data/models/diagnosis_model.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/categoria_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/repositories/diagnosis_repository.dart';

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
        categoria.dbValue,
      );
      return data.map((json) => DiagnosisModel.fromJson(json)).toList();
    }, context: 'filtrar los diagnósticos por categoría');
  }

  @override
  Future<void> agregarDiagnosis(Diagnosis diagnosis) {
    return runGuarded(() async {
      final model = DiagnosisModel(
        nombre: diagnosis.nombre,
        descripcion: diagnosis.descripcion,
        severidadDefault: diagnosis.severidadDefault,
        alcance: diagnosis.alcance,
        categoria: diagnosis.categoria,
        claveOdontograma: diagnosis.claveOdontograma,
      );
      await remoteDataSource.createDiagnosis(model.toJson());
    }, context: 'crear el diagnóstico');
  }

  @override
  Future<void> actualizarDiagnosis(Diagnosis diagnosis) {
    return runGuarded(() async {
      if (diagnosis.id == null) return;
      final model = DiagnosisModel(
        id: diagnosis.id,
        nombre: diagnosis.nombre,
        descripcion: diagnosis.descripcion,
        severidadDefault: diagnosis.severidadDefault,
        alcance: diagnosis.alcance,
        categoria: diagnosis.categoria,
        claveOdontograma: diagnosis.claveOdontograma,
      );
      await remoteDataSource.updateDiagnosis(diagnosis.id!, model.toJson());
    }, context: 'actualizar el diagnóstico');
  }

  @override
  Future<void> eliminarDiagnosisDelCatalogo(String id) {
    return runGuarded(
      () => remoteDataSource.deleteDiagnosis(id),
      context: 'eliminar el diagnóstico',
    );
  }
}
