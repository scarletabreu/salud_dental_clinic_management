import 'package:salud_dental_clinic_management/features/tratamiento/data/datasources/tratamiento_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/data/models/tratamiento_model.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/repositories/tratamiento_repository.dart';

class TratamientoRepositoryImpl implements TratamientoRepository {
  final TratamientoRemoteDatasource remoteDataSource;

  TratamientoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Tratamiento>> getCatalogoTratamientos() async {
    final data = await remoteDataSource.fetchTratamientos();
    return data.map((json) => TratamientoModel.fromJson(json)).toList();
  }

  @override
  Future<void> guardarTratamiento(Tratamiento tratamiento) async {
    final model = TratamientoModel(
      id: tratamiento.id,
      nombre: tratamiento.nombre,
      descripcion: tratamiento.descripcion,
      costo: tratamiento.costo,
      contraindicaciones: tratamiento.contraindicaciones,
      alcance: tratamiento.alcance,
    );

    final Map<String, dynamic> data = model.toJson();

    data['deleted_at'] = null;
    data['updated_at'] = DateTime.now().toIso8601String();

    await remoteDataSource.upsertTratamiento(data);
  }

  @override
  Future<void> eliminarTratamiento(String id) async {
    await remoteDataSource.deleteTratamiento(id);
  }
}
