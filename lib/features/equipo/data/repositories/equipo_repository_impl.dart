import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/repositories/equipo_repository.dart';
import '../datasources/equipo_remote_datasource.dart';
import '../models/equipo_model.dart';

class EquipoRepositoryImpl implements EquipoRepository {
  final EquipoRemoteDatasource remoteDataSource;

  EquipoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Equipo>> getInventarioEquipos() {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchEquipos();
      return data.map((json) => EquipoModel.fromJson(json)).toList();
    }, context: 'obtener el inventario de equipos');
  }

  @override
  Future<void> registrarOActualizarEquipo(Equipo equipo) {
    return runGuarded(() async {
      final model = EquipoModel(
        id: equipo.id,
        nombre: equipo.nombre,
        descripcion: equipo.descripcion,
        ultimoMantenimiento: equipo.ultimoMantenimiento,
        tiempoParaMantenimiento: equipo.tiempoParaMantenimiento,
      );

      final data = model.toJson();
      data['deleted_at'] = null;
      data['updated_at'] = DateTime.now().toIso8601String();

      await remoteDataSource.upsertEquipo(data);
    }, context: 'registrar o actualizar el equipo');
  }

  @override
  Future<void> eliminarEquipo(String id) {
    return runGuarded(
      () => remoteDataSource.softDeleteEquipo(id),
      context: 'eliminar el equipo',
    );
  }
}
