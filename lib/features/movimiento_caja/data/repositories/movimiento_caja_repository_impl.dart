import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/repositories/movimiento_caja_repository.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/data/datasources/movimiento_caja_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/data/models/movimiento_caja_model.dart';

class MovimientoCajaRepositoryImpl implements MovimientoCajaRepository {
  final MovimientoCajaRemoteDatasource remoteDataSource;

  MovimientoCajaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> crearMovimiento(MovimientoCaja movimiento) {
    return runGuarded(() async {
      final model = MovimientoCajaModel.fromEntity(movimiento);
      await remoteDataSource.registrarMovimiento(model.toJson());
    }, context: 'crear el movimiento');
  }

  @override
  Future<List<MovimientoCaja>> getMovimientosDeHoy(String cajaDiariaId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchMovimientosPorCaja(cajaDiariaId);
      return data.map((json) => MovimientoCajaModel.fromJson(json)).toList();
    }, context: 'obtener los movimientos');
  }
}
