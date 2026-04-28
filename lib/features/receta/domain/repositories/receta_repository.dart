import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

abstract class RecetaRepository {
  Future<void> emitirReceta(Receta receta);
  Future<void> editarReceta(Receta receta);
  Future<void> cancelarReceta(String id);
  Future<List<Receta>> getHistorialRecetas(String pacienteId);
}
