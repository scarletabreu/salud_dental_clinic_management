import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/repositories/equipo_repository.dart';
import '../datasources/equipo_remote_datasource.dart';
import '../models/equipo_model.dart';

class EquipoRepositoryImpl implements EquipoRepository {
  final EquipoRemoteDatasource remoteDataSource;

  EquipoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Equipo>> getInventarioEquipos() async {
    try {
      final data = await remoteDataSource.fetchEquipos();
      return data.map((json) => EquipoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error en el repositorio al obtener inventario: $e');
    }
  }

  @override
  Future<void> registrarOActualizarEquipo(Equipo equipo) async {
    try {
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
    } catch (e) {
      throw Exception(
        'Error en el repositorio al registrar/actualizar equipo: $e',
      );
    }
  }

  @override
  Future<void> eliminarEquipo(String id) async {
    try {
      await remoteDataSource.softDeleteEquipo(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar equipo: $e');
    }
  }
}
