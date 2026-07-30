import 'package:salud_dental_clinic_management/features/medicina/data/datasources/medicina_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicinaRemoteDatasourceImpl implements MedicinaRemoteDatasource {
  final SupabaseClient supabaseClient;

  MedicinaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchMedicinas() async {
    final medicinasResp = await supabaseClient
        .from('medicinas')
        .select('*')
        .filter('deleted_at', 'is', null);

    final listMedicinas = List<Map<String, dynamic>>.from(
      medicinasResp as List,
    );
    if (listMedicinas.isEmpty) return listMedicinas;

    final contrasResp = await supabaseClient
        .from('contraindicaciones')
        .select('*')
        .filter('deleted_at', 'is', null);

    final listContras = List<Map<String, dynamic>>.from(contrasResp as List);

    for (final med in listMedicinas) {
      final medId = med['id'];
      med['contraindicaciones'] = listContras
          .where((c) => c['medicina_id'] == medId)
          .toList();
    }

    return listMedicinas;
  }

  @override
  Future<Map<String, dynamic>> insertMedicina(Map<String, dynamic> data) async {
    data.remove('id');
    data.remove('created_at');
    data.remove('updated_at');

    final response = await supabaseClient
        .from('medicinas')
        .insert(data)
        .select()
        .single();

    return response as Map<String, dynamic>;
  }

  @override
  Future<void> upsertMedicina(Map<String, dynamic> data) async {
    if (!(_isValidUuid(data['id']))) {
      data.remove('id');
    }
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('medicinas').upsert(data);
  }

  bool _isValidUuid(dynamic id) {
    return id != null && id is String && id.length == 36 && id.contains('-');
  }

  @override
  Future<void> softDeleteMedicina(String id) async {
    await supabaseClient
        .from('medicinas')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
