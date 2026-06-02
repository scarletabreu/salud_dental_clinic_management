import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';

abstract class ConsumibleRepository {
  Future<List<Consumible>> getInventario();
  Future<void> actualizarExistencia(String id, int nuevoStock);
  Future<void> guardarConsumible(Consumible consumible);
  Future<void> eliminarConsumible(String id);
}
