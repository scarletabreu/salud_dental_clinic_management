import 'package:salud_dental_clinic_management/features/paciente/data/models/paciente_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PacienteRemoteDatasource {
  final SupabaseClient client;

  PacienteRemoteDatasource(this.client);

  Future<List<PacienteModel>> getPacientes() async {
    final response = await client.from('pacientes').select();
    return (response as List)
        .map((json) => PacienteModel.fromJson(json))
        .toList();
  }

  Future<void> addPaciente(PacienteModel paciente) async {
    await client.from('pacientes').insert(paciente.toJson());
  }

  Future<void> updatePaciente(PacienteModel paciente) async {
    await client
        .from('pacientes')
        .update(paciente.toJson())
        .eq('id', paciente.id);
  }

  Future<void> deletePaciente(String id) async {
    await client.from('pacientes').delete().eq('id', id);
  }
}
