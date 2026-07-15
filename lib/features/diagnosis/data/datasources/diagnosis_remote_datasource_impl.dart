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
        .filter('deleted_at', 'is', null)
        .order('nombre', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDiagnosisByCategoria(
    String categoria,
  ) async {
    final response = await supabaseClient
        .from('diagnosticos')
        .select()
        .eq('categoria', categoria)
        .filter('deleted_at', 'is', null);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> createDiagnosis(Map<String, dynamic> data) async {
    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('diagnosticos').insert(data);
  }

  @override
  Future<void> updateDiagnosis(String id, Map<String, dynamic> data) async {
    data.remove('id');
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('diagnosticos').update(data).eq('id', id);
  }

  @override
  Future<void> deleteDiagnosis(String id) async {
    await supabaseClient
        .from('diagnosticos')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
