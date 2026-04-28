import 'package:salud_dental_clinic_management/features/procedimiento/data/datasources/procedimiento_remore_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProcedimientoRemoteDatasourceImpl
    implements ProcedimientoRemoteDatasource {
  final SupabaseClient supabaseClient;

  ProcedimientoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchProcedimientos() async {
    final response = await supabaseClient
        .from('procedimientos')
        .select('*, contraindicaciones(*)')
        .isFilter('deleted_at', null)
        .order('nombre', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> upsertProcedimiento(Map<String, dynamic> data) async {
    await supabaseClient.from('procedimientos').upsert(data);
  }

  @override
  Future<void> softDeleteProcedimiento(String id) async {
    await supabaseClient
        .from('procedimientos')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
