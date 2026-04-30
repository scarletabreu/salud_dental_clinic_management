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
      await supabase.from('citas').insert(cita.toCreateJson());
    } catch (e) {
      throw Exception('Error al agregar cita: $e');
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
}
