import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/cuenta/data/datasources/cuenta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/cuenta/data/models/cuenta_model.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
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
  Future<Cuenta> getCuentaById(String id) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchCuentaById(id);
      if (data == null) {
        // Se lanza un Failure tipado directamente: el mapper de errores lo
        // respeta tal cual (case 0) y conserva este mensaje para el usuario.
        throw const ServerFailure('No se encontró la cuenta solicitada.');
      }
      return CuentaModel.fromJson(data);
    }, context: 'obtener la cuenta');
  }

  @override
  Future<Cuenta?> getCuentaByConsultaId(String id) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchCuentaByConsultaId(id);
      if (data == null) {
        // Se lanza un Failure tipado directamente: el mapper de errores lo
        // respeta tal cual (case 0) y conserva este mensaje para el usuario.
        throw const ServerFailure('No se encontró la cuenta solicitada.');
      }
      return CuentaModel.fromJson(data);
    }, context: 'obtener la cuenta');
  }

  @override
  Future<void> fijarModoPago(String cuentaId, MetodoPago modo) {
    return runGuarded(
      () => remoteDataSource.fijarModoPago(cuentaId, modo),
      context: 'guardar el modo de pago de la cuenta',
    );
  }

  @override
  Future<void> eliminarCuenta(String id) {
    return runGuarded(
      () => remoteDataSource.deleteCuenta(id),
      context: 'eliminar la cuenta',
    );
  }
}
