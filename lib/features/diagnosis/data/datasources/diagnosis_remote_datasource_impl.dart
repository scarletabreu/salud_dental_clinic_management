import 'package:salud_dental_clinic_management/features/diagnosis/data/datasources/diagnosis_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiagnosisRemoteDatasourceImpl implements DiagnosisRemoteDatasource {
  final SupabaseClient supabaseClient;

  DiagnosisRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchCatalogoDiagnosis() async {
    try {
      final response = await supabaseClient
          .from('diagnosticos')
          .select()
          .filter('deleted_at', 'is', null)
          .order('nombre', ascending: true);
      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al cargar catálogo de diagnósticos: ${e.message}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDiagnosisByCategoria(
    String categoria,
  ) async {
    try {
      final response = await supabaseClient
          .from('diagnosticos')
          .select()
          .eq('categoria', categoria)
          .filter('deleted_at', 'is', null);
      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al filtrar diagnósticos por categoría: ${e.message}',
      );
    }
  }

  @override
  Future<void> createDiagnosis(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('diagnosticos').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar nuevo diagnóstico: ${e.message}');
    }
  }

  @override
  Future<void> deleteDiagnosis(String id) async {
    try {
      await supabaseClient
          .from('diagnosticos')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar diagnóstico: ${e.message}');
    }
  }
}
