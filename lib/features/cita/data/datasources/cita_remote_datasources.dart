import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';

class CitaRemoteDataSource {
  final SupabaseClient supabase;

  CitaRemoteDataSource(this.supabase);

  Future<List<CitaModel>> fetchCitas() async {
    try {
      final response = await supabase
          .from('citas')
          .select(
            '*, doctor:personas!doctor_id(*), persona:personas!persona_id(*)',
          )
          .filter('deleted_at', 'is', null);

      return (response as List)
          .map((json) => CitaModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener citas: $e');
    }
  }

  Future<List<CitaModel>> fetchCitasByPaciente(String pacienteId) async {
    try {
      final response = await supabase
          .from('citas')
          .select(
            '*, doctor:personas!doctor_id(*), persona:personas!persona_id(*)',
          )
          .eq('persona_id', pacienteId)
          .filter('deleted_at', 'is', null);

      return (response as List)
          .map((json) => CitaModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener citas del paciente: $e');
    }
  }

  Future<void> addCita(CitaModel cita) async {
    try {
      final data = cita.toJson();

      if (!(_isValidUuid(data['id']))) {
        data.remove('id');
      }
      data['created_at'] = DateTime.now().toIso8601String();
      await supabase.from('citas').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al agregar cita: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al agregar cita: $e');
    }
  }

  Future<void> updateCita(CitaModel cita) async {
    if (cita.id == null) {
      throw Exception('No se puede actualizar una cita sin un ID.');
    }
    try {
      final data = cita.toJson();
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabase.from('citas').update(data).eq('id', cita.id!);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar cita: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar cita: $e');
    }
  }

  Future<void> deleteCita(String id) async {
    try {
      await supabase
          .from('citas')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al borrar cita: $e');
    }
  }

  bool _isValidUuid(dynamic id) {
    return id != null && id is String && id.length == 36 && id.contains('-');
  }
}
