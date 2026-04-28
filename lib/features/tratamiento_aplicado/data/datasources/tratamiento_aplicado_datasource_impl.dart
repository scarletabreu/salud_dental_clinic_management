import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/datasources/tratamiento_aplicado_datasource.dart';

class TratamientoAplicadoDatasourceImpl
    implements TratamientoAplicadoDatasource {
  final SupabaseClient supabaseClient;

  TratamientoAplicadoDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> registrarTratamiento(Map<String, dynamic> data) async {
    await supabaseClient.from('tratamientos_aplicados').insert(data);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPorPaciente(String pacienteId) async {
    final response = await supabaseClient
        .from('tratamientos_aplicados')
        .select('*, tratamiento:tratamientos(*)')
        .eq('paciente_id', pacienteId)
        .isFilter('deleted_at', null);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> marcarComoTerminado(String id) async {
    await supabaseClient
        .from('tratamientos_aplicados')
        .update({'esta_terminado': true})
        .eq('id', id);
  }

  @override
  Future<void> eliminarTratamiento(String id) async {
    await supabaseClient
        .from('tratamientos_aplicados')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
