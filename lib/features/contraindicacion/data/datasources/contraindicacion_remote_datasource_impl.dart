import 'package:flutter/foundation.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/data/datasources/contraindicacion_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContraindicacionRemoteDatasourceImpl
    implements ContraindicacionRemoteDatasource {
  final SupabaseClient supabaseClient;

  ContraindicacionRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByCondicion(
    String condicionId,
  ) async {
    final response = await supabaseClient
        .from('contraindicaciones')
        .select('*')
        .eq('condicion_id', condicionId)
        .filter('deleted_at', 'is', null);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByTratamiento(
    String tratamientoId,
  ) async {
    final response = await supabaseClient
        .from('contraindicaciones')
        .select('*')
        .eq('tratamiento_id', tratamientoId)
        .filter('deleted_at', 'is', null);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByProcedimiento(
    String procedimientoId,
  ) async {
    final response = await supabaseClient
        .from('contraindicaciones')
        .select('*')
        .eq('procedimiento_id', procedimientoId)
        .filter('deleted_at', 'is', null);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByMedicina(
    String medicinaId,
  ) async {
    final response = await supabaseClient
        .from('contraindicaciones')
        .select('*')
        .eq('medicina_id', medicinaId)
        .filter('deleted_at', 'is', null);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<Map<String, dynamic>> registrarContraindicacion(
    Map<String, dynamic> data,
  ) async {
    try {
      final Map<String, dynamic> payload = Map<String, dynamic>.from(data);

      payload['updated_at'] = DateTime.now().toIso8601String();

      if (payload['medicina_id'] == null ||
          payload['medicina_id'].toString().isEmpty ||
          payload['medicina_id'] == '00000000-0000-0000-0000-000000000000') {
        payload.remove('medicina_id');
      }

      if (payload['tratamiento_id'] == null ||
          payload['tratamiento_id'].toString().isEmpty) {
        payload.remove('tratamiento_id');
      }

      if (payload['procedimiento_id'] == null ||
          payload['procedimiento_id'].toString().isEmpty) {
        payload.remove('procedimiento_id');
      }

      final rawId = payload['id'];
      final bool esNuevoId =
          rawId == null ||
          rawId.toString().isEmpty ||
          !rawId.toString().contains('-') ||
          rawId.toString().length != 36;

      if (esNuevoId) {
        payload.remove('id');
        payload['created_at'] = DateTime.now().toIso8601String();

        if (kDebugMode) {
          print('🚀 Registrando nueva contraindicación (INSERT): $payload');
        }

        final response = await supabaseClient
            .from('contraindicaciones')
            .insert(payload)
            .select()
            .single();

        return Map<String, dynamic>.from(response);
      } else {
        if (kDebugMode) {
          print(
            '🚀 Actualizando contraindicación existente (UPSERT): $payload',
          );
        }

        final response = await supabaseClient
            .from('contraindicaciones')
            .upsert(payload)
            .select()
            .single();

        return Map<String, dynamic>.from(response);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ ERROR EN REGISTRAR CONTRAINDICACION: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteContraindicacion(String id) async {
    await supabaseClient
        .from('contraindicaciones')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
