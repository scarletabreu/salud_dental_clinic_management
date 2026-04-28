import '../entities/equipo_mantenimiento.dart';

abstract class EquipoMantenimientoRepository {
  Future<List<EquipoMantenimiento>> getHistorialMantenimientos(String equipoId);
  Future<void> registrarMantenimiento(EquipoMantenimiento mantenimiento);
  Future<void> eliminarRegistroMantenimiento(String id);
}
