/// Resultado confirmado del cierre de una consulta.
///
/// Lo devuelve tanto el cierre real como el reintento del mismo intento
/// lógico: si llega dos veces, describe la misma operación, nunca una segunda.
class ResultadoCierreConsulta {
  final String consultaId;
  final String? cuentaId;
  final double montoTotal;
  final String? citaEstado;
  final DateTime? finalizadaEn;

  /// Consumibles descontados, con la cantidad que salió del inventario.
  final Map<String, int> consumoPorConsumible;

  final int recetasEmitidas;

  const ResultadoCierreConsulta({
    required this.consultaId,
    this.cuentaId,
    this.montoTotal = 0,
    this.citaEstado,
    this.finalizadaEn,
    this.consumoPorConsumible = const {},
    this.recetasEmitidas = 0,
  });

  factory ResultadoCierreConsulta.fromRpc(Map<String, dynamic> json) {
    final consumo = <String, int>{};
    for (final fila in (json['movimientos'] as List? ?? const [])) {
      if (fila is! Map) continue;
      final id = fila['consumible_id']?.toString();
      if (id == null) continue;
      consumo[id] = (fila['cantidad'] as num?)?.toInt() ?? 0;
    }

    return ResultadoCierreConsulta(
      consultaId: json['consulta_id']?.toString() ?? '',
      cuentaId: json['cuenta_id']?.toString(),
      montoTotal: (json['monto_total'] as num?)?.toDouble() ?? 0,
      citaEstado: json['cita_estado']?.toString(),
      finalizadaEn: DateTime.tryParse(json['finalizada_en']?.toString() ?? ''),
      consumoPorConsumible: consumo,
      recetasEmitidas: (json['recetas_emitidas'] as List? ?? const []).length,
    );
  }
}
