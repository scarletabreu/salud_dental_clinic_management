abstract class CajaDiariaDatasource {
  Future<void> abrirCaja(double montoInicial);
  Future<void> registrarMovimiento(Map<String, dynamic> movimientoData);
  Future<List<Map<String, dynamic>>> fetchMovimientosDelDia();
  Future<void> cerrarCaja(Map<String, dynamic> datosCierre);
  Future<bool> isCajaAbierta();
  Future<double> getBalanceActual();
  Future<Map<String, dynamic>?> fetchCajaAbierta();

  /// Cajas de días anteriores que quedaron sin cerrar. Ya no bloquean el
  /// trabajo de hoy, pero siguen siendo un pendiente contable.
  Future<List<Map<String, dynamic>>> fetchCajasSinCerrarDeOtrosDias();

  /// Movimientos vivos de una caja concreta, la de hoy o la de cualquier día.
  Future<List<Map<String, dynamic>>> fetchMovimientosDeCaja(String cajaId);

  /// Movimientos vivos de varias cajas en una sola consulta.
  ///
  /// El aviso de arqueos pendientes necesita el esperado de cada uno; pedirlos
  /// de a uno convertiría cada refresco de la pantalla en N viajes.
  Future<List<Map<String, dynamic>>> fetchMovimientosDeCajas(
    List<String> cajaIds,
  );

  /// Balance de una caja concreta: apertura + ingresos - egresos.
  Future<double> getBalanceDeCaja(String cajaId);

  /// Cierra la caja indicada. Falla si otra sesión ya la cerró.
  Future<void> cerrarCajaPorId(
    String cajaId,
    Map<String, dynamic> datosCierre,
  );

  Stream<List<Map<String, dynamic>>> watchMovimientos(String cajaDiariaId);
}
