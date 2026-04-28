import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';

abstract class DiagnosticoAplicadoRepository {
  Future<void> aplicarDiagnostico(DiagnosticoAplicado diagnostico);
  Future<List<DiagnosticoAplicado>> getDiagnosticosDeConsulta(
    String consultaId,
  );
  Future<void> eliminarDiagnostico(String id);
}
