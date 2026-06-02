import 'package:salud_dental_clinic_management/features/equipo_mantenimiento/domain/entities/equipo_mantenimiento.dart';
import 'package:salud_dental_clinic_management/features/equipo_mantenimiento/domain/repositories/equipo_mantenimiento_repository.dart';
import '../datasources/equipo_mantenimiento_remote_datasource.dart';
import '../models/equipo_mantenimiento_model.dart';

class EquipoMantenimientoRepositoryImpl
    implements EquipoMantenimientoRepository {
  final EquipoMantenimientoRemoteDatasource remoteDataSource;

  EquipoMantenimientoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<EquipoMantenimientoModel>> getHistorialMantenimientos(
    String equipoId,
  ) async {
    try {
      final data = await remoteDataSource.fetchMantenimientosByEquipo(equipoId);
      return data
          .map((json) => EquipoMantenimientoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener historial de mantenimientos: $e',
      );
    }
  }

  @override
  Future<void> registrarMantenimiento(EquipoMantenimiento mantenimiento) async {
    try {
      final model = EquipoMantenimientoModel(
        id: mantenimiento.id,
        equipoId: mantenimiento.equipoId,
        consumibleId: mantenimiento.consumibleId,
        descripcion: mantenimiento.descripcion,
        suplidorId: mantenimiento.suplidorId,
        costo: mantenimiento.costo,
      );

      final data = model.toJson();
      data['deleted_at'] = null;

      await remoteDataSource.insertMantenimiento(data);
    } catch (e) {
      throw Exception('Error en el repositorio al registrar mantenimiento: $e');
    }
  }

  @override
  Future<void> eliminarRegistroMantenimiento(String id) async {
    try {
      await remoteDataSource.softDeleteMantenimiento(id);
    } catch (e) {
      throw Exception(
        'Error en el repositorio al eliminar registro de mantenimiento: $e',
      );
    }
  }
}
