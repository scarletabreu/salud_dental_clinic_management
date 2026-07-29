import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/categoria_diagnosis.dart';

abstract class DiagnosisRepository {
  Future<List<Diagnosis>> getCatalogoCompleto();
  Future<List<Diagnosis>> getDiagnosisPorCategoria(
    CategoriaDiagnosis categoria,
  );
  Future<void> agregarDiagnosis(Diagnosis diagnosis);
  Future<void> actualizarDiagnosis(Diagnosis diagnosis);
  Future<void> eliminarDiagnosisDelCatalogo(String id);
}
