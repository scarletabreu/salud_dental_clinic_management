import 'package:salud_dental_clinic_management/features/paciente/data/models/paciente_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PacienteRemoteDatasource {
  final SupabaseClient client;

  PacienteRemoteDatasource(this.client);

  Future<List<PacienteModel>> getPacientes() async {
    final response = await client
        .from('pacientes')
        .select()
        .isFilter('deleted_at', null)
        .order('nombre', ascending: true);

    return (response as List)
        .map((json) => PacienteModel.fromJson(json))
        .toList();
  }

  Future<void> addPaciente(PacienteModel paciente) async {
    final data = paciente.toJson();
    data['deleted_at'] = null;
    await client.from('pacientes').insert(data);
  }

  Future<void> updatePaciente(PacienteModel paciente) async {
    final data = paciente.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();

    await client.from('pacientes').update(data).eq('id', paciente.id);
  }

  Future<void> deletePaciente(String id) async {
    await client
        .from('pacientes')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
