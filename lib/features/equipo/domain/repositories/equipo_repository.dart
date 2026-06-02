import '../entities/equipo.dart';

abstract class EquipoRepository {
  Future<List<Equipo>> getInventarioEquipos();
  Future<void> registrarOActualizarEquipo(Equipo equipo);
  Future<void> eliminarEquipo(String id);
}
