import 'package:salud_dental_clinic_management/features/diagnosis/data/datasources/diagnosis_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiagnosisRemoteDatasourceImpl implements DiagnosisRemoteDatasource {
  final SupabaseClient supabaseClient;

  DiagnosisRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchCatalogoDiagnosis() async {
    final response = await supabaseClient
        .from('diagnosticos')
        .select()
        .isFilter('deleted_at', null)
        .order('nombre', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDiagnosisByCategoria(
    String categoria,
  ) async {
    final response = await supabaseClient
        .from('diagnosticos')
        .select()
        .eq('categoria', categoria)
        .isFilter('deleted_at', null);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> deleteDiagnosis(String id) async {
    await supabaseClient
        .from('diagnosticos')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
