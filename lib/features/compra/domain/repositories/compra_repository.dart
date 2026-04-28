import 'package:salud_dental_clinic_management/features/compra/domain/entities/compra.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/enums/estado_compra.dart';

abstract class CompraRepository {
  Future<List<Compra>> fetchCompras();
  Future<Compra?> getCompraById(String id);
  Future<void> registrarCompra(Compra compra);
  Future<void> actualizarEstadoCompra(String id, EstadoCompra nuevoEstado);
  Future<void> cancelarCompra(String id);
}
