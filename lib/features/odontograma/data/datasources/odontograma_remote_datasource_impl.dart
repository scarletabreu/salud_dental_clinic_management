import 'package:salud_dental_clinic_management/features/odontograma/data/datasources/odontograma_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OdontogramaRemoteDatasourceImpl implements OdontogramaRemoteDatasource {
  final SupabaseClient supabaseClient;

  OdontogramaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<Map<String, dynamic>?> fetchOdontogramaByConsulta(
    String consultaId,
  ) async {
    return await supabaseClient
        .from('odontogramas')
        .select(
          '*, dientes:dientes(*, diagnosis:diagnosticos_aplicados(*), tratamientos:tratamientos_aplicados(*))',
        )
        .eq('consulta_id', consultaId)
        .filter('deleted_at', 'is', null)
        .maybeSingle();
  }

  @override
  Future<void> crearOdontograma(Map<String, dynamic> data) async {
    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('odontogramas').insert(data);
  }

  @override
  Future<void> actualizarOdontograma(Map<String, dynamic> data) async {
    data.remove('id');
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('odontogramas').upsert(data);
  }

  @override
  Future<void> eliminarOdontograma(String id) async {
    await supabaseClient
        .from('odontogramas')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
