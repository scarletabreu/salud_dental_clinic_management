import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/entities/compra.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/repositories/compra_repository.dart';
import 'package:salud_dental_clinic_management/features/compra/data/datasources/compra_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/compra/data/models/compra_model.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/enums/estado_compra.dart';

class CompraRepositoryImpl implements CompraRepository {
  final CompraRemoteDatasource remoteDataSource;

  CompraRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Compra>> fetchCompras() {
    return runGuarded(() async {
      final comprasData = await remoteDataSource.fetchCompras();
      return comprasData.map((data) => CompraModel.fromJson(data)).toList();
    }, context: 'obtener la lista de compras');
  }

  @override
  Future<Compra?> getCompraById(String id) {
    return runGuarded(() async {
      final compraData = await remoteDataSource.fetchCompraById(id);
      return (compraData != null) ? CompraModel.fromJson(compraData) : null;
    }, context: 'buscar la compra');
  }

  @override
  Future<void> registrarCompra(Compra compra) {
    return runGuarded(() async {
      final model = CompraModel(
        id: compra.id,
        fecha: compra.fecha,
        items: compra.items,
        estado: compra.estado,
      );
      await remoteDataSource.createCompra(model);
    }, context: 'registrar la compra');
  }

  @override
  Future<void> actualizarEstadoCompra(String id, EstadoCompra nuevoEstado) {
    return runGuarded(
      () => remoteDataSource.updateCompraEstado(id, nuevoEstado.name),
      context: 'actualizar el estado de la compra',
    );
  }

  @override
  Future<void> cancelarCompra(String id) {
    return runGuarded(
      () => remoteDataSource.deleteCompra(id),
      context: 'cancelar la compra',
    );
  }
}
