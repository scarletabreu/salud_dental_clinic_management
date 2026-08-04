import 'package:salud_dental_clinic_management/features/documento_clinico/data/datasources/documento_clinico_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentoClinicoDatasourceImpl implements DocumentoClinicoDatasource {
  final SupabaseClient supabaseClient;

  DocumentoClinicoDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> crearDocumento(Map<String, dynamic> data) async {
    data.remove('id');
    data['created_at'] = DateTime.now().toUtc().toIso8601String();
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await supabaseClient.from('documentos_clinicos').insert(data);
  }

  @override
  Future<void> subirDocumento(Map<String, dynamic> data) async {
    await crearDocumento(data);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDocumentosPaciente(
    String pacienteId,
  ) async {
    final response = await supabaseClient
        .from('documentos_clinicos')
        .select()
        .eq('paciente_id', pacienteId)
        .filter('deleted_at', 'is', null)
        .order('fecha_creacion', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> eliminarDocumento(String id) async {
    await supabaseClient
        .from('documentos_clinicos')
        .update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }
}
