import 'package:salud_dental_clinic_management/features/receta/data/datasources/receta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/item_receta_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecetaRemoteDatasourceImpl implements RecetaRemoteDatasource {
  final SupabaseClient supabaseClient;

  RecetaRemoteDatasourceImpl({required this.supabaseClient});

  static const _selectRecetaCompleta = '''
    *,
    items_receta(*),
    doctor:doctores(id, usuarios(personas(nombre, apellido)))
  ''';

  @override
  Future<String> emitirRecetaCompleta({
    required RecetaModel receta,
    required List<ItemRecetaModel> items,
  }) async {
    final payloadCabecera = receta.toCabeceraJson();

    final res = await supabaseClient
        .from('recetas')
        .insert(payloadCabecera)
        .select('id')
        .single();

    final recetaId = res['id'] as String;

    if (items.isNotEmpty) {
      final itemsPayload = items
          .map((i) => i.toJson(recetaId: recetaId))
          .toList();
      await supabaseClient.from('items_receta').insert(itemsPayload);
    }

    return recetaId;
  }

  @override
  Future<void> anularReceta({
    required String recetaId,
    required String motivo,
  }) async {
    final now = DateTime.now().toIso8601String();
    await supabaseClient
        .from('recetas')
        .update({
          'estado': 'anulada',
          'motivo_anulacion': motivo,
          'updated_at': now,
        })
        .eq('id', recetaId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecetasByPaciente(
    String pacienteId,
  ) async {
    final response = await supabaseClient
        .from('recetas')
        .select(_selectRecetaCompleta)
        .eq('paciente_id', pacienteId)
        .isFilter('deleted_at', null)
        .order('fecha_emision', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecetasByConsulta(
    String consultaId,
  ) async {
    final response = await supabaseClient
        .from('recetas')
        .select(_selectRecetaCompleta)
        .eq('consulta_id', consultaId)
        .isFilter('deleted_at', null)
        .order('fecha_emision', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }
}
