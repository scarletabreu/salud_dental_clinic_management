import 'package:salud_dental_clinic_management/features/evaluacion_clinica/domain/entities/evaluacion_clinica.dart';

abstract class EvaluacionClinicaRepository {
  /// Deja registrada la evaluación de una consulta y le cuelga sus hallazgos.
  /// Idempotente: llamarla otra vez devuelve la misma evaluación.
  Future<String> registrarEvaluacionDeConsulta(EvaluacionClinica evaluacion);

  Future<EvaluacionClinica?> getEvaluacionDeConsulta(String consultaId);

  Future<List<EvaluacionClinica>> getEvaluacionesPaciente(String pacienteId);
}
