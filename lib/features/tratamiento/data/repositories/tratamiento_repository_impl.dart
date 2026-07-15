import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/repositories/tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/data/datasources/tratamiento_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/data/models/tratamiento_model.dart';

class TratamientoRepositoryImpl implements TratamientoRepository {
  final TratamientoRemoteDatasource remoteDataSource;

  TratamientoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Tratamiento>> getCatalogoTratamientos() {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchTratamientos();
      return data.map((json) => TratamientoModel.fromJson(json)).toList();
    }, context: 'obtener el catálogo de tratamientos');
  }

  @override
  Future<void> guardarTratamiento(Tratamiento tratamiento) {
    return runGuarded(() async {
      final model = TratamientoModel(
        id: tratamiento.id,
        nombre: tratamiento.nombre,
        descripcion: tratamiento.descripcion,
        costo: tratamiento.costo,
        contraindicaciones: tratamiento.contraindicaciones,
        alcance: tratamiento.alcance,
      );

      final Map<String, dynamic> data = model.toJson();

      if (tratamiento.id == null || tratamiento.id!.isEmpty) {
        data['deleted_at'] = null;
        await remoteDataSource.createTratamiento(data);
      } else {
        data['updated_at'] = DateTime.now().toIso8601String();
        await remoteDataSource.updateTratamiento(tratamiento.id!, data);
      }
    }, context: 'guardar el tratamiento');
  }

  @override
  Future<void> eliminarTratamiento(String id) {
    return runGuarded(
      () => remoteDataSource.deleteTratamiento(id),
      context: 'eliminar el tratamiento',
    );
  }
}
