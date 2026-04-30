import 'package:salud_dental_clinic_management/features/orden_medica/domain/entities/orden_medica.dart';
import 'package:salud_dental_clinic_management/features/orden_medica/domain/repositories/orden_medica_repository.dart';
import 'package:salud_dental_clinic_management/features/orden_medica/data/datasources/orden_medica_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/orden_medica/data/models/orden_medica_model.dart';

class OrdenMedicaRepositoryImpl implements OrdenMedicaRepository {
  final OrdenMedicaRemoteDatasource remoteDataSource;

  OrdenMedicaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> emitirOrden(OrdenMedica orden) async {
    try {
      final model = OrdenMedicaModel.fromEntity(orden);
      final data = model.toJson();
      data['deleted_at'] = null;
      await remoteDataSource.insertarOrden(data);
    } catch (e) {
      throw Exception('Error en el repositorio al emitir orden médica: $e');
    }
  }

  @override
  Future<void> editarOrden(OrdenMedica orden) async {
    try {
      final model = OrdenMedicaModel.fromEntity(orden);
      final data = model.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();
      await remoteDataSource.actualizarOrden(data);
    } catch (e) {
      throw Exception('Error en el repositorio al editar orden médica: $e');
    }
  }

  @override
  Future<void> anularOrden(String id) async {
    try {
      await remoteDataSource.eliminarOrden(id);
    } catch (e) {
      throw Exception('Error en el repositorio al anular orden médica: $e');
    }
  }

  @override
  Future<List<OrdenMedica>> getHistorialDeOrdenes(String pacienteId) async {
    try {
      final data = await remoteDataSource.fetchOrdenesPorPaciente(pacienteId);
      return data.map((json) => OrdenMedicaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener historial de órdenes: $e',
      );
    }
  }
}
