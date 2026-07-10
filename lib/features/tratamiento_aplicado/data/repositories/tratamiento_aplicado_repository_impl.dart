import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/repositories/tratamiento_aplicado_repository.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/datasources/tratamiento_aplicado_datasource.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/models/tratamiento_aplicado_model.dart';

class TratamientoAplicadoRepositoryImpl
    implements TratamientoAplicadoRepository {
  final TratamientoAplicadoDatasource remoteDataSource;

  TratamientoAplicadoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> realizarTratamiento(TratamientoAplicado tratamiento) {
    return runGuarded(() async {
      final model = TratamientoAplicadoModel(
        id: tratamiento.id,
        tratamientoId: tratamiento.tratamientoId,
        tratamientoPadreId: tratamiento.tratamientoPadreId,
        esContinuo: tratamiento.esContinuo,
        estaTerminado: tratamiento.estaTerminado,
        consultaId: tratamiento.consultaId,
        dienteId: tratamiento.dienteId,
        superficie: tratamiento.superficie,
        precioAplicado: tratamiento.precioAplicado,
        notas: tratamiento.notas,
      );

      final data = model.toJson();
      data['deleted_at'] = null;

      await remoteDataSource.registrarTratamiento(data);
    }, context: 'realizar el tratamiento');
  }

  @override
  Future<List<TratamientoAplicado>> getHistorialClinico(String pacienteId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchPorPaciente(pacienteId);
      return data
          .map((json) => TratamientoAplicadoModel.fromJson(json))
          .toList();
    }, context: 'obtener el historial clínico');
  }

  @override
  Future<void> finalizarTratamiento(String id) {
    return runGuarded(
      () => remoteDataSource.marcarComoTerminado(id),
      context: 'finalizar el tratamiento',
    );
  }

  @override
  Future<void> eliminarTratamientoAplicado(String id) {
    return runGuarded(
      () => remoteDataSource.eliminarTratamiento(id),
      context: 'eliminar el tratamiento aplicado',
    );
  }
}
