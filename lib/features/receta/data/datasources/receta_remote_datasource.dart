import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/tem_receta_model.dart';

abstract class RecetaRemoteDatasource {
  Future<String> emitirRecetaCompleta({
    required RecetaModel receta,
    required List<ItemRecetaModel> items,
  });

  Future<void> anularReceta({required String recetaId, required String motivo});

  Future<List<Map<String, dynamic>>> fetchRecetasByPaciente(String pacienteId);
  Future<List<Map<String, dynamic>>> fetchRecetasByConsulta(String consultaId);
}
