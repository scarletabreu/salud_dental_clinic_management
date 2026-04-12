class Equipo {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime ultimoMantenimiento;
  final int tiempoParaMantenimiento;

  Equipo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.ultimoMantenimiento,
    required this.tiempoParaMantenimiento,
  });
}
