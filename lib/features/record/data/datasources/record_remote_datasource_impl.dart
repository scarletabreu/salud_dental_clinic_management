import 'package:salud_dental_clinic_management/features/record/data/datasources/record_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecordRemoteDatasourceImpl implements RecordRemoteDatasource {
  final SupabaseClient supabaseClient;

  RecordRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<Map<String, dynamic>?> fetchRecordByPaciente(String pacienteId) async {
    return await supabaseClient
        .from('records')
        .select('*, consultas(*)')
        .eq('paciente_id', pacienteId)
        .filter('deleted_at', 'is', null)
        .maybeSingle();
  }

  @override
  Future<void> createRecord(Map<String, dynamic> data) async {
    data.remove('id');

    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;

    await supabaseClient.from('records').insert(data);
  }

  @override
  Future<void> upsertRecord(Map<String, dynamic> data) async {
    data.remove('id');
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('records').upsert(data);
  }

  @override
  Future<void> anularRecord(String id) async {
    await supabaseClient
        .from('records')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  // ── Condiciones del paciente (puente record_condicion) ────────────────────

  @override
  Future<String?> fetchRecordId(String pacienteId) async {
    final res = await supabaseClient
        .from('records')
        .select('id')
        .eq('paciente_id', pacienteId)
        .filter('deleted_at', 'is', null)
        .maybeSingle();
    return res?['id'] as String?;
  }

  @override
  Future<String> getOrCreateRecordId(String pacienteId) async {
    print('DEBUG getOrCreateRecordId START pacienteId=$pacienteId');
    final existente = await fetchRecordId(pacienteId);
    print('DEBUG fetchRecordId existente=$existente');
    if (existente != null) return existente;

    // Solo columnas garantizadas en la BD real: `paciente_id` y `tipo_sangre`
    // son NOT NULL; el resto tiene default. (El `schema.sql` del repo está
    // desfasado: no incluir `condiciones`, que no existe en la tabla real.)
    final now = DateTime.now().toIso8601String();
    print('DEBUG creando nueva fila records');
    final creado = await supabaseClient
        .from('records')
        .insert({
          'paciente_id': pacienteId,
          'tipo_sangre': 'desconocido',
          'created_at': now,
          'updated_at': now,
        })
        .select('id')
        .single();
    print('DEBUG creado id=${creado['id']}');
    return creado['id'] as String;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAflicciones(String recordId) async {
    final response = await supabaseClient
        .from('record_condicion')
        .select('record_id, condicion_id, fecha_deteccion, condiciones(*)')
        .eq('record_id', recordId);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> addAfliccion(String recordId, String condicionId) async {
    // `record_condicion` no tiene constraint única en (record_id, condicion_id)
    // en la BD real (el dump miente), así que no se puede usar upsert/onConflict:
    // se verifica existencia y solo se inserta si falta (la UI además ya excluye
    // las condiciones ya asignadas del selector).
    final existente = await supabaseClient
        .from('record_condicion')
        .select('condicion_id')
        .eq('record_id', recordId)
        .eq('condicion_id', condicionId)
        .maybeSingle();
    if (existente != null) return;

    await supabaseClient.from('record_condicion').insert({
      'record_id': recordId,
      'condicion_id': condicionId,
      'fecha_deteccion': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> removeAfliccion(String recordId, String condicionId) async {
    await supabaseClient
        .from('record_condicion')
        .delete()
        .eq('record_id', recordId)
        .eq('condicion_id', condicionId);
  }
}
