import 'package:salud_dental_clinic_management/features/documento_clinico/data/datasources/documento_clinico_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentoClinicoDatasourceImpl implements DocumentoClinicoDatasource {
  final SupabaseClient supabaseClient;

  DocumentoClinicoDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> subirDocumento(Map<String, dynamic> data) async {
    await supabaseClient.from('documentos_clinicos').insert(data);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDocumentosPaciente(
    String pacienteId,
  ) async {
    final response = await supabaseClient
        .from('documentos_clinicos')
        .select()
        .eq('paciente_id', pacienteId)
        .isFilter('deleted_at', null)
        .order('fecha_creacion', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> eliminarDocumento(String id) async {
    await supabaseClient
        .from('documentos_clinicos')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
