import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

abstract class RecetaRepository {
  Future<String> emitirReceta(Receta receta);
  Future<void> reemitirRecetaModificada({
    required String recetaOriginalId,
    required String motivoReemplazo,
    required Receta nuevaReceta,
  });
  Future<void> anularReceta(String recetaId, String motivo);
  Future<List<Receta>> getHistorialRecetasPaciente(String pacienteId);
  Future<List<Receta>> getRecetasConsulta(String consultaId);
}
