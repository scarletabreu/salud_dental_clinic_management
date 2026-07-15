import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/repositories/pago_repository.dart';
import 'package:salud_dental_clinic_management/features/pago/data/datasources/pago_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/pago/data/models/pago_model.dart';

class PagoRepositoryImpl implements PagoRepository {
  final PagoRemoteDatasource remoteDataSource;

  PagoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> procesarPago(Pago pago) {
    return runGuarded(() async {
      final data = PagoModel.fromEntity(pago).toJson();
      data['deleted_at'] = null;
      await remoteDataSource.registrarPago(data);
    }, context: 'procesar el pago');
  }

  @override
  Future<void> editarPago(Pago pago) {
    return runGuarded(() async {
      final data = PagoModel.fromEntity(pago).toJson();
      data['updated_at'] = DateTime.now().toIso8601String();
      await remoteDataSource.actualizarPago(data);
    }, context: 'editar el pago');
  }

  @override
  Future<void> cancelarPago(String id) {
    return runGuarded(
      () => remoteDataSource.anularPago(id),
      context: 'cancelar el pago',
    );
  }

  @override
  Future<List<Pago>> getHistorialPagosCuenta(String cuentaId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchPagosPorCuenta(cuentaId);
      return data.map((json) => PagoModel.fromJson(json)).toList();
    }, context: 'obtener el historial de pagos');
  }
}
