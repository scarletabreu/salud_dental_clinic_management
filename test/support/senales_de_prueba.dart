import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';

/// Fábrica de canales falsa para tests: expone los callbacks de cada tabla
/// para simular eventos (`cambios`) y estados del websocket (`estados`).
///
/// Se usa junto con `SenalesRealtime(fabrica: ..., debounce: Duration.zero)`
/// para que la señal llegue en el siguiente turno del event loop.
class FabricaCanalesFalsa implements FabricaCanalesSenal {
  final Map<String, void Function()> cambios = {};
  final Map<String, void Function(EstadoCanalSenal)> estados = {};
  final List<String> tablasAbiertas = [];
  int canalesCerrados = 0;

  @override
  CanalSenal abrir(
    String tabla, {
    required void Function() onCambio,
    required void Function(EstadoCanalSenal estado) onEstado,
  }) {
    tablasAbiertas.add(tabla);
    cambios[tabla] = onCambio;
    estados[tabla] = onEstado;
    return _CanalFalso(() => canalesCerrados++);
  }
}

class _CanalFalso implements CanalSenal {
  _CanalFalso(this._alCerrar);
  final void Function() _alCerrar;

  @override
  Future<void> cerrar() async => _alCerrar();
}
