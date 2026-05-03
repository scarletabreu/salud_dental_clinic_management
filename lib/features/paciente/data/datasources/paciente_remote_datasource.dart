import 'package:salud_dental_clinic_management/features/paciente/data/models/paciente_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PacienteRemoteDatasource {
  final SupabaseClient client;

  PacienteRemoteDatasource(this.client);

  Future<List<PacienteModel>> getPacientes() async {
    try {
      final response = await client
          .from('pacientes')
          .select()
          .filter('deleted_at', 'is', null)
          .order('nombre', ascending: true);

      return (response as List)
          .map((json) => PacienteModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener lista de pacientes: ${e.message}');
    }
  }

  Future<void> addPaciente(PacienteModel paciente) async {
    try {
      final data = paciente.toJson();
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      if (!(_isValidUuid(data['id']))) {
        data.remove('id');
      }

      await client.from('pacientes').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar nuevo paciente: ${e.message}');
    }
  }

  Future<void> updatePaciente(PacienteModel paciente) async {
    try {
      final data = paciente.toJson();
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();

      await client.from('pacientes').update(data).eq('id', paciente.id!);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar paciente: ${e.message}');
    }
  }

  Future<void> deletePaciente(String id) async {
    try {
      await client
          .from('pacientes')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar paciente: ${e.message}');
    }
  }

  bool _isValidUuid(dynamic id) {
    return id != null && id is String && id.length == 36 && id.contains('-');
  }
}
