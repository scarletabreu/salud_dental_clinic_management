import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/models/consulta_model.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/models/odontograma_model.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultaRemoteDatasourceImpl implements ConsultaRemoteDatasource {
  final SupabaseClient supabaseClient;

  ConsultaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> crearConsulta(ConsultaModel consulta) async {
    try {
      final Map<String, dynamic> consultaData = consulta.toJson();

      final now = DateTime.now().toIso8601String();
      consultaData['created_at'] = now;
      consultaData['updated_at'] = now;

      final response = await supabaseClient
          .from('consultas')
          .insert(consultaData)
          .select('id')
          .single();

      final String consultaId = response['id'];

      if (consulta.odontograma != null) {
        final odontoJson = (consulta.odontograma as OdontogramaModel).toJson();
        odontoJson['consulta_id'] = consultaId;
        odontoJson.remove('id');
        await supabaseClient.from('odontograma').insert(odontoJson);
      }

      for (var receta in consulta.recetas) {
        final recetaJson = (receta as RecetaModel).toJson();
        recetaJson['consulta_id'] = consultaId;
        recetaJson.remove('id');
        await supabaseClient.from('recetas').insert(recetaJson);
      }
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar consulta completa: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al registrar consulta: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  ) async {
    try {
      final response = await supabaseClient
          .from('consultas')
          .select('*, recetas(*), odontograma(*), documentos_clinicos(*)')
          .eq('paciente_id', pacienteId)
          .isFilter('deleted_at', null)
          .order('fecha', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener historial de consultas: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchConsultaById(String id) async {
    try {
      return await supabaseClient
          .from('consultas')
          .select('*, recetas(*), odontograma(*), documentos_clinicos(*)')
          .eq('id', id)
          .isFilter('deleted_at', null)
          .maybeSingle();
    } on PostgrestException catch (e) {
      throw Exception('Error al recuperar consulta clínica: ${e.message}');
    }
  }

  @override
  Future<void> updateConsulta(
    String id,
    Map<String, dynamic> consultaData,
  ) async {
    try {
      consultaData.remove('id');
      consultaData['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('consultas').update(consultaData).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar consulta: ${e.message}');
    }
  }

  @override
  Future<void> deleteConsulta(String id) async {
    try {
      await supabaseClient
          .from('consultas')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar consulta: ${e.message}');
    }
  }
}
