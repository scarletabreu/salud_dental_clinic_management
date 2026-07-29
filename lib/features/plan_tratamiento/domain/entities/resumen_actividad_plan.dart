enum TipoEjecucionItemPlan {
  unica,
  porSesiones;

  String get dbValue => this == TipoEjecucionItemPlan.porSesiones ? 'por_sesiones' : 'unica';

  static TipoEjecucionItemPlan fromDb(String? valor) =>
      valor == 'por_sesiones' ? TipoEjecucionItemPlan.porSesiones : TipoEjecucionItemPlan.unica;

  String get etiqueta =>
      this == TipoEjecucionItemPlan.porSesiones ? 'Por sesiones' : 'Única';
}

class ResumenActividadPlan {
  final String itemPlanId;
  final String planId;
  final String? pacienteId;
  final String tratamientoId;
  final String tratamientoNombre;
  final TipoEjecucionItemPlan tipoEjecucion;
  final int? sesionesPlanificadas;
  final String estado;
  final double montoPresupuestado;
  final double cantidadRealizada;
  final double montoRealizado;
  final double montoFacturado;
  final double montoPagado;
  final double montoPendiente;

  const ResumenActividadPlan({
    required this.itemPlanId,
    required this.planId,
    this.pacienteId,
    required this.tratamientoId,
    required this.tratamientoNombre,
    required this.tipoEjecucion,
    this.sesionesPlanificadas,
    required this.estado,
    required this.montoPresupuestado,
    required this.cantidadRealizada,
    required this.montoRealizado,
    required this.montoFacturado,
    required this.montoPagado,
    required this.montoPendiente,
  });

  double? get progresoSesiones {
    if (tipoEjecucion == TipoEjecucionItemPlan.unica) return null;
    if (sesionesPlanificadas == null || sesionesPlanificadas == 0) return null;
    return (cantidadRealizada / sesionesPlanificadas!).clamp(0, 1);
  }

  bool get facturaCompleta => montoFacturado >= montoPresupuestado;
  bool get pagoCompleto => montoPagado >= montoFacturado && montoFacturado > 0;
}