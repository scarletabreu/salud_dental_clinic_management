import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/repositories/pago_repository.dart';
import 'package:salud_dental_clinic_management/features/pago/data/datasources/pago_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/pago/data/models/pago_model.dart';

class PagoRepositoryImpl implements PagoRepository {
  final PagoRemoteDatasource remoteDataSource;

  PagoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> procesarPago(Pago pago) async {
    try {
      final model = PagoModel.fromEntity(pago);
      final data = model.toJson();
      data['deleted_at'] = null;
      await remoteDataSource.registrarPago(data);
    } catch (e) {
      throw Exception('Error al procesar el pago: $e');
    }
  }

  @override
  Future<void> editarPago(Pago pago) async {
    try {
      final model = PagoModel.fromEntity(pago);
      final data = model.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();
      await remoteDataSource.actualizarPago(data);
    } catch (e) {
      throw Exception('Error al editar el pago: $e');
    }
  }

  @override
  Future<void> cancelarPago(String id) async {
    try {
      await remoteDataSource.anularPago(id);
    } catch (e) {
      throw Exception('Error al cancelar el pago: $e');
    }
  }

  @override
  Future<List<Pago>> getHistorialPagosCuenta(String cuentaId) async {
    try {
      final data = await remoteDataSource.fetchPagosPorCuenta(cuentaId);
      return data.map((json) => PagoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener el historial de pagos: $e');
    }
  }
}
