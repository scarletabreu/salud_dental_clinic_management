import 'package:salud_dental_clinic_management/features/auditoria/data/datasources/auditoria_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditoriaRemoteDatasourceImpl implements AuditoriaRemoteDatasource {
  final SupabaseClient supabaseClient;

  AuditoriaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchLineaTiempo(String consultaId) async {
    // Una sola llamada: la RPC ya cruza los eventos de la cita con los de la
    // consulta y resuelve el nombre del actor. Pedirlo por separado sería un
    // N+1 por evento contra `personas`.
    final filas = await supabaseClient.rpc(
      'linea_tiempo_consulta',
      params: {'p_consulta_id': consultaId},
    );
    return [
      for (final fila in (filas as List? ?? const []))
        Map<String, dynamic>.from(fila as Map),
    ];
  }
}
