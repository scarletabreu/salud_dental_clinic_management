import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/orden_medica/domain/entities/orden_medica.dart';
import 'package:salud_dental_clinic_management/features/orden_medica/domain/repositories/orden_medica_repository.dart';
import 'package:salud_dental_clinic_management/features/orden_medica/data/datasources/orden_medica_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/orden_medica/data/models/orden_medica_model.dart';

class OrdenMedicaRepositoryImpl implements OrdenMedicaRepository {
  final OrdenMedicaRemoteDatasource remoteDataSource;

  OrdenMedicaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> emitirOrden(OrdenMedica orden) {
    return runGuarded(() async {
      final data = OrdenMedicaModel.fromEntity(orden).toJson();
      data['deleted_at'] = null;
      await remoteDataSource.insertarOrden(data);
    }, context: 'emitir la orden médica');
  }

  @override
  Future<void> editarOrden(OrdenMedica orden) {
    return runGuarded(() async {
      final data = OrdenMedicaModel.fromEntity(orden).toJson();
      data['updated_at'] = DateTime.now().toIso8601String();
      await remoteDataSource.actualizarOrden(data);
    }, context: 'editar la orden médica');
  }

  @override
  Future<void> anularOrden(String id) {
    return runGuarded(
      () => remoteDataSource.eliminarOrden(id),
      context: 'anular la orden médica',
    );
  }

  @override
  Future<List<OrdenMedica>> getHistorialDeOrdenes(String pacienteId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchOrdenesPorPaciente(pacienteId);
      return data.map((json) => OrdenMedicaModel.fromJson(json)).toList();
    }, context: 'obtener el historial de órdenes');
  }
}
