import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/repositories/pago_repository.dart';
import 'package:salud_dental_clinic_management/features/pago/data/datasources/pago_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/pago/data/models/pago_model.dart';

class PagoRepositoryImpl implements PagoRepository {
  final PagoRemoteDatasource remoteDataSource;

  PagoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> cancelarPago(String id, {String? motivo}) {
    return runGuarded(
      () => remoteDataSource.anularPago(id, motivo: motivo),
      context: 'anular el cobro',
    );
  }

  @override
  Future<List<Pago>> getHistorialPagosCuenta(String cuentaId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchPagosPorCuenta(cuentaId);
      return data.map((json) => PagoModel.fromJson(json)).toList();
    }, context: 'obtener el historial de pagos');
  }

  @override
  Future<String> registrarPago({
    required String cuentaId,
    required double monto,
    required MetodoPago metodo,
    String? cuotaId,
  }) {
    return runGuarded(
      () => remoteDataSource.registrarPagoTransaccional(
        cuentaId: cuentaId,
        monto: monto,
        metodoPago: metodo.dbValue,
        cuotaId: cuotaId,
      ),
      context: 'registrar el pago',
    );
  }
}
