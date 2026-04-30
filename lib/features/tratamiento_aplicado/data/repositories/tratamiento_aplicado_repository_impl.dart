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
    try {
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
    } catch (e) {
      throw Exception('Error en el repositorio al realizar tratamiento: $e');
    }
  }

  @override
  Future<List<TratamientoAplicado>> getHistorialClinico(
    String pacienteId,
  ) async {
    try {
      final data = await remoteDataSource.fetchPorPaciente(pacienteId);
      return data
          .map((json) => TratamientoAplicadoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener historial clínico: $e',
      );
    }
  }

  @override
  Future<void> finalizarTratamiento(String id) async {
    try {
      await remoteDataSource.marcarComoTerminado(id);
    } catch (e) {
      throw Exception('Error en el repositorio al finalizar tratamiento: $e');
    }
  }

  @override
  Future<void> eliminarTratamientoAplicado(String id) async {
    try {
      await remoteDataSource.eliminarTratamiento(id);
    } catch (e) {
      throw Exception(
        'Error en el repositorio al eliminar tratamiento aplicado: $e',
      );
    }
  }
}
