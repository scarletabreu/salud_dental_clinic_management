import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';

class CitaRemoteDataSource {
  final SupabaseClient supabase;

  CitaRemoteDataSource(this.supabase);

  Future<List<CitaModel>> fetchCitas() async {
    final response = await supabase
        .from('citas')
        .select(
          '*, doctor:personas!doctor_id(*), persona:personas!persona_id(*)',
        )
        .isFilter('deleted_at', null);

    return (response as List).map((json) => CitaModel.fromJson(json)).toList();
  }

  Future<List<CitaModel>> fetchCitasByPaciente(String pacienteId) async {
    final response = await supabase
        .from('citas')
        .select(
          '*, doctor:personas!doctor_id(*), persona:personas!persona_id(*)',
        )
        .eq('persona_id', pacienteId)
        .isFilter('deleted_at', null);

    return (response as List).map((json) => CitaModel.fromJson(json)).toList();
  }

  Future<void> addCita(CitaModel cita) async {
    await supabase.from('citas').insert(cita.toJson());
  }

  Future<void> deleteCita(String id) async {
    await supabase
        .from('citas')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
