import 'package:salud_dental_clinic_management/features/compra/domain/entities/compra.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/repositories/compra_repository.dart';
import 'package:salud_dental_clinic_management/features/compra/data/datasources/compra_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/compra/data/models/compra_model.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/enums/estado_compra.dart';

class CompraRepositoryImpl implements CompraRepository {
  final CompraRemoteDatasource remoteDataSource;

  CompraRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Compra>> fetchCompras() async {
    try {
      final comprasData = await remoteDataSource.fetchCompras();
      return comprasData.map((data) => CompraModel.fromJson(data)).toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener lista de compras: $e',
      );
    }
  }

  @override
  Future<Compra?> getCompraById(String id) async {
    try {
      final compraData = await remoteDataSource.fetchCompraById(id);
      return (compraData != null) ? CompraModel.fromJson(compraData) : null;
    } catch (e) {
      throw Exception('Error en el repositorio al buscar compra: $e');
    }
  }

  @override
  Future<void> registrarCompra(Compra compra) async {
    try {
      final model = CompraModel(
        id: compra.id,
        fecha: compra.fecha,
        items: compra.items,
        estado: compra.estado,
      );
      await remoteDataSource.createCompra(model);
    } catch (e) {
      throw Exception('Error en el repositorio al registrar compra: $e');
    }
  }

  @override
  Future<void> actualizarEstadoCompra(
    String id,
    EstadoCompra nuevoEstado,
  ) async {
    try {
      await remoteDataSource.updateCompraEstado(id, nuevoEstado.name);
    } catch (e) {
      throw Exception('Error en el repositorio al actualizar estado: $e');
    }
  }

  @override
  Future<void> cancelarCompra(String id) async {
    try {
      await remoteDataSource.deleteCompra(id);
    } catch (e) {
      throw Exception('Error en el repositorio al cancelar compra: $e');
    }
  }
}
