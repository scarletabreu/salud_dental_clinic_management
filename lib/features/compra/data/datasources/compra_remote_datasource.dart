import 'package:salud_dental_clinic_management/features/compra/data/models/compra_model.dart';

abstract class CompraRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchCompras();
  Future<Map<String, dynamic>?> fetchCompraById(String id);
  Future<void> createCompra(CompraModel compra);
  Future<void> updateCompraEstado(String id, String nuevoEstado);
  Future<void> deleteCompra(String id);
}
