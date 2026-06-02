import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/data/datasources/cuenta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/cuenta/data/models/cuenta_model.dart';

class CuentaRepositoryImpl implements CuentaRepository {
  final CuentaRemoteDatasource remoteDataSource;

  CuentaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Cuenta>> getHistorialFinanciero(String pacienteId) async {
    try {
      final data = await remoteDataSource.fetchCuentasByPaciente(pacienteId);
      return data.map((json) => CuentaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener historial financiero: $e',
      );
    }
  }

  @override
  Future<void> crearFactura(Cuenta cuenta) async {
    try {
      final model = CuentaModel(
        id: cuenta.id,
        consultaId: cuenta.consultaId,
        fechaCreacion: cuenta.fechaCreacion,
        metodoPago: cuenta.metodoPago,
        itemCuentas: cuenta.itemCuentas,
        nota: cuenta.nota,
      );
      await remoteDataSource.registrarCuenta(model.toJson());
    } catch (e) {
      throw Exception('Error en el repositorio al crear factura: $e');
    }
  }

  @override
  Future<void> eliminarCuenta(String id) async {
    try {
      await remoteDataSource.deleteCuenta(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar cuenta: $e');
    }
  }
}
