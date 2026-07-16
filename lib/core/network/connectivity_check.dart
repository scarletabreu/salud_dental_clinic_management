import 'package:connectivity_plus/connectivity_plus.dart';

/// Comprobación de conectividad de red. Reporta si hay alguna interfaz activa
/// (wifi, datos, ethernet), no si el backend responde de verdad: la fuente de
/// verdad completa de "estamos offline" es esto más los [NetworkFailure] que
/// producen las peticiones reales.
abstract class ConnectivityCheck {
  Future<bool> get hasConnection;
  Stream<bool> get onStatusChange;
}

class ConnectivityCheckImpl implements ConnectivityCheck {
  final Connectivity _connectivity;

  ConnectivityCheckImpl([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get hasConnection async {
    try {
      return _isOnline(await _connectivity.checkConnectivity());
    } catch (_) {
      // En Linux sin NetworkManager (iwd/systemd-networkd), connectivity_plus
      // lanza un error de D-Bus en vez de reportar el estado. No podemos
      // determinarlo: asumimos online y dejamos que la petición real sea la
      // fuente de verdad (produce NetworkFailure si de verdad estamos offline).
      return true;
    }
  }

  @override
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnline).handleError((_) {});

  /// connectivity_plus v6 devuelve una lista de interfaces; hay conexión si
  /// alguna es distinta de `none`.
  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
