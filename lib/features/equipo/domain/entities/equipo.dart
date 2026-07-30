class Equipo {
  final String? id;
  final String nombre;
  final String descripcion;
  final DateTime ultimoMantenimiento;
  final int tiempoParaMantenimiento;

  Equipo({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.ultimoMantenimiento,
    required this.tiempoParaMantenimiento,
  });

  DateTime get proximoMantenimiento => DateTime(
    ultimoMantenimiento.year,
    ultimoMantenimiento.month,
    ultimoMantenimiento.day,
  ).add(Duration(days: tiempoParaMantenimiento));

  int diasParaMantenimiento(DateTime hoy) {
    final fecha = DateTime(hoy.year, hoy.month, hoy.day);
    return proximoMantenimiento.difference(fecha).inDays;
  }

  bool mantenimientoVencidoEn(DateTime hoy) => diasParaMantenimiento(hoy) <= 0;
}
