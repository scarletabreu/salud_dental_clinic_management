enum FrecuenciaCuota {
  semanal,
  quincenal,
  mensual;

  String get label => switch (this) {
    FrecuenciaCuota.semanal => 'Semanal',
    FrecuenciaCuota.quincenal => 'Quincenal',
    FrecuenciaCuota.mensual => 'Mensual',
  };

  DateTime fechaDesde(DateTime primeraFecha, int indice) {
    final base = DateTime(
      primeraFecha.year,
      primeraFecha.month,
      primeraFecha.day,
    );

    return switch (this) {
      FrecuenciaCuota.semanal => base.add(Duration(days: 7 * indice)),
      FrecuenciaCuota.quincenal => base.add(Duration(days: 15 * indice)),
      FrecuenciaCuota.mensual => _sumarMeses(base, indice),
    };
  }

  static DateTime _sumarMeses(DateTime fecha, int meses) {
    final totalMeses = fecha.year * 12 + fecha.month - 1 + meses;
    final year = totalMeses ~/ 12;
    final month = totalMeses % 12 + 1;
    final ultimoDia = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, fecha.day.clamp(1, ultimoDia));
  }
}
