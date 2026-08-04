import 'package:supabase_flutter/supabase_flutter.dart';

import 'senales_realtime.dart';

/// Canales reales sobre `postgres_changes`.
///
/// Un canal por tabla, sin filtros de cliente: el recorte por rol lo hace
/// Postgres con las policies RLS antes de emitir cada evento. El payload no
/// se mira — la señal sólo dice «recarga».
class FabricaCanalesSupabase implements FabricaCanalesSenal {
  FabricaCanalesSupabase(this._client);

  final SupabaseClient _client;

  @override
  CanalSenal abrir(
    String tabla, {
    required void Function() onCambio,
    required void Function(EstadoCanalSenal estado) onEstado,
  }) {
    final canal = _client
        .channel('senal:$tabla')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tabla,
          callback: (_) => onCambio(),
        )
        .subscribe((status, error) {
          switch (status) {
            case RealtimeSubscribeStatus.subscribed:
              onEstado(EstadoCanalSenal.suscrito);
            case RealtimeSubscribeStatus.channelError:
            case RealtimeSubscribeStatus.closed:
            case RealtimeSubscribeStatus.timedOut:
              onEstado(EstadoCanalSenal.caido);
          }
        });

    return _CanalSupabase(_client, canal);
  }
}

class _CanalSupabase implements CanalSenal {
  _CanalSupabase(this._client, this._canal);

  final SupabaseClient _client;
  final RealtimeChannel _canal;

  @override
  Future<void> cerrar() => _client.removeChannel(_canal);
}
