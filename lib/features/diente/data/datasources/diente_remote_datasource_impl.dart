import 'package:salud_dental_clinic_management/features/diente/data/datasources/diente_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DienteRemoteDatasourceImpl implements DienteRemoteDatasource {
  final SupabaseClient supabaseClient;

  DienteRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchDientesByOdontograma(
    String odontogramaId,
  ) async {
    final response = await supabaseClient
        .from('dientes')
        .select('*')
        .eq('odontograma_id', odontogramaId)
        .filter('deleted_at', 'is', null);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> updateDiente(String id, Map<String, dynamic> data) async {
    await supabaseClient.from('dientes').update(data).eq('id', id);
  }

  @override
  Future<void> deleteDienteData(String id) async {
    await supabaseClient
        .from('dientes')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
