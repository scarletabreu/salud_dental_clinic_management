import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/repositories/tratamiento_aplicado_repository.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/datasources/tratamiento_aplicado_datasource.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/models/tratamiento_aplicado_model.dart';

class TratamientoAplicadoRepositoryImpl
    implements TratamientoAplicadoRepository {
  final TratamientoAplicadoDatasource remoteDataSource;

  TratamientoAplicadoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> realizarTratamiento(TratamientoAplicado tratamiento) async {
    final model = TratamientoAplicadoModel(
      id: tratamiento.id,
      tratamientoId: tratamiento.tratamientoId,
      tratamientoPadreId: tratamiento.tratamientoPadreId,
      esContinuo: tratamiento.esContinuo,
      estaTerminado: tratamiento.estaTerminado,
    );

    final data = model.toJson();
    data['deleted_at'] = null;

    await remoteDataSource.registrarTratamiento(data);
  }

  @override
  Future<List<TratamientoAplicado>> getHistorialClinico(
    String pacienteId,
  ) async {
    final data = await remoteDataSource.fetchPorPaciente(pacienteId);
    return data.map((json) => TratamientoAplicadoModel.fromJson(json)).toList();
  }

  @override
  Future<void> finalizarTratamiento(String id) async {
    await remoteDataSource.marcarComoTerminado(id);
  }

  @override
  Future<void> eliminarTratamientoAplicado(String id) async {
    await remoteDataSource.eliminarTratamiento(id);
  }
}
