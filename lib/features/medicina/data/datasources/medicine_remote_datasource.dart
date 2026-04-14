import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/medicina_model.dart';

class MedicineRemoteDatasource {
  final SupabaseClient client;

  MedicineRemoteDatasource(this.client);

  Future<List<MedicinaModel>> getMedicinas() async {
    final response = await client
        .from('medicinas')
        .select();

    final data = response as List<dynamic>;

    return data
        .map((json) => MedicinaModel.fromJson(json))
        .toList();
  }

  Future<MedicinaModel> getMedicinaById(String id) async {
    final response = await client
        .from('medicinas')
        .select()
        .eq('id', id)
        .single();

    return MedicinaModel.fromJson(response);
  }

  Future<void> createMedicina(MedicinaModel medicina) async {
    await client
        .from('medicinas')
        .insert(medicina.toJson());
  }

  Future<void> updateMedicina(MedicinaModel medicina) async {
    await client
        .from('medicinas')
        .update(medicina.toJson())
        .eq('id', medicina.id);
  }

  Future<void> deleteMedicina(String id) async {
    await client
        .from('medicinas')
        .delete()
        .eq('id', id);
  }
}