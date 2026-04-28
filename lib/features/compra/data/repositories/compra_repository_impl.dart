import 'package:salud_dental_clinic_management/features/compra/data/datasources/compra_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/compra/data/models/compra_model.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/entities/compra.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/enums/estado_compra.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/repositories/compra_repository.dart';

class CompraRepositoryImpl implements CompraRepository {
  final CompraRemoteDatasource remoteDataSource;

  CompraRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Compra>> fetchCompras() async {
    final comprasData = await remoteDataSource.fetchCompras();
    return comprasData.map((data) => CompraModel.fromJson(data)).toList();
  }

  @override
  Future<Compra?> getCompraById(String id) async {
    final compraData = await remoteDataSource.fetchCompraById(id);
    return (compraData != null) ? CompraModel.fromJson(compraData) : null;
  }

  @override
  Future<void> registrarCompra(Compra compra) async {
    final model = CompraModel(
      id: compra.id,
      fecha: compra.fecha,
      items: compra.items,
      estado: compra.estado,
    );

    await remoteDataSource.createCompra(model.toJson());
  }

  @override
  Future<void> actualizarEstadoCompra(
    String id,
    EstadoCompra nuevoEstado,
  ) async {
    await remoteDataSource.updateCompraEstado(id, nuevoEstado.name);
  }

  @override
  Future<void> cancelarCompra(String id) async {
    await remoteDataSource.deleteCompra(id);
  }
}
