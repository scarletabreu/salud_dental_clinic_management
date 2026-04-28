import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/data/datasources/pago_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/pago/data/models/pago_model.dart';

abstract class PagoRepository {
  Future<void> procesarPago(Pago pago);
  Future<void> editarPago(Pago pago);
  Future<void> cancelarPago(String id);
  Future<List<Pago>> getHistorialPagosCuenta(String cuentaId);
}

class PagoRepositoryImpl implements PagoRepository {
  final PagoRemoteDatasource remoteDataSource;

  PagoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> procesarPago(Pago pago) async {
    final model = PagoModel.fromEntity(pago);
    final data = model.toJson();
    data['deleted_at'] = null; // Registro activo
    await remoteDataSource.registrarPago(data);
  }

  @override
  Future<void> editarPago(Pago pago) async {
    final model = PagoModel.fromEntity(pago);
    final data = model.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();
    await remoteDataSource.actualizarPago(data);
  }

  @override
  Future<void> cancelarPago(String id) async {
    await remoteDataSource.anularPago(id);
  }

  @override
  Future<List<Pago>> getHistorialPagosCuenta(String cuentaId) async {
    final data = await remoteDataSource.fetchPagosPorCuenta(cuentaId);
    return data.map((json) => PagoModel.fromJson(json)).toList();
  }
}
