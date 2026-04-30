import 'package:salud_dental_clinic_management/features/documento_clinico/data/datasources/documento_clinico_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentoClinicoDatasourceImpl implements DocumentoClinicoDatasource {
  final SupabaseClient supabaseClient;

  DocumentoClinicoDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> crearDocumento(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('documentos_clinicos').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar el documento clínico: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear documento: $e');
    }
  }

  @override
  Future<void> subirDocumento(Map<String, dynamic> data) async {
    await crearDocumento(data);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDocumentosPaciente(
    String pacienteId,
  ) async {
    try {
      final response = await supabaseClient
          .from('documentos_clinicos')
          .select()
          .eq('paciente_id', pacienteId)
          .filter('deleted_at', 'is', null)
          .order('fecha_creacion', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al recuperar documentos del paciente: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al buscar documentos: $e');
    }
  }

  @override
  Future<void> eliminarDocumento(String id) async {
    try {
      await supabaseClient
          .from('documentos_clinicos')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar el documento: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar: $e');
    }
  }
}
