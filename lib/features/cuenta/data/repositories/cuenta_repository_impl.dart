import 'package:salud_dental_clinic_management/core/errors/failures.dart';
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
Future<void> actualizarCuenta(Cuenta cuenta) async {
  if (cuenta.id == null) {
    throw Exception(
      'No se puede actualizar una cuenta sin id (¿aún no se ha creado?)',
    );
  }
  try {
    final model = CuentaModel(
      id: cuenta.id,
      consultaId: cuenta.consultaId,
      fechaCreacion: cuenta.fechaCreacion,
      fechaPago: cuenta.fechaPago,
      metodoPago: cuenta.metodoPago,
      estado: cuenta.estado,
      itemCuentas: cuenta.itemCuentas,
      nota: cuenta.nota,
    );
    // toJson() incluye 'id' solo si es un uuid válido; para update lo
    // necesitamos en el WHERE del datasource, no en el body, así que
    // lo removemos del payload explícitamente.
    final data = model.toJson()..remove('id');
    await remoteDataSource.updateCuenta(cuenta.id!, data);
  } catch (e) {
    throw Exception('Error en el repositorio al actualizar cuenta: $e');
  }
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
  Future<void> crearFactura(Cuenta cuenta) {
    return runGuarded(() async {
      final model = CuentaModel(
        id: cuenta.id,
        consultaId: cuenta.consultaId,
        fechaCreacion: cuenta.fechaCreacion,
        metodoPago: cuenta.metodoPago,
        itemCuentas: cuenta.itemCuentas,
        estado: cuenta.estado,
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
