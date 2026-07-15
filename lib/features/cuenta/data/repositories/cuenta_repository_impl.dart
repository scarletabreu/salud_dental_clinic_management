import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/cuenta/data/datasources/cuenta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/cuenta/data/models/cuenta_model.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';

class CuentaRepositoryImpl implements CuentaRepository {
  final CuentaRemoteDatasource remoteDataSource;

  CuentaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Cuenta>> getCuentasPorCobrar() {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchTodasLasCuentas();
      return data.map((json) => CuentaModel.fromJson(json)).toList();
    }, context: 'obtener las cuentas por cobrar');
  }

  @override
  Future<List<Cuenta>> getHistorialFinanciero(String pacienteId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchCuentasByPaciente(pacienteId);
      return data.map((json) => CuentaModel.fromJson(json)).toList();
    }, context: 'obtener el historial financiero');
  }

  @override
  Future<void> crearFactura(Cuenta cuenta) {
    return runGuarded(() async {
      final model = CuentaModel(
        id: cuenta.id,
        consultaId: cuenta.consultaId,
        fechaCreacion: cuenta.fechaCreacion,
        metodoPago: cuenta.metodoPago,
        itemCuentas: cuenta.itemCuentas,
        nota: cuenta.nota,
      );
      await remoteDataSource.registrarCuenta(model.toJson());
    }, context: 'crear la factura');
  }

  @override
  Future<void> eliminarCuenta(String id) {
    return runGuarded(
      () => remoteDataSource.deleteCuenta(id),
      context: 'eliminar la cuenta',
    );
  }
}
