import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/asistente_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/data/datasources/asistente_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/asistente_model.dart';

class AsistenteRepositoryImpl implements AsistenteRepository {
  final AsistenteRemoteDatasource remoteDataSource;

  AsistenteRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> createAsistente(String userId) async {
    try {
      await remoteDataSource.createAsistente(userId);
    } catch (e) {
      throw Exception('Error en el repositorio al crear asistente: $e');
    }
  }

  @override
  Future<void> deleteAsistente(String userId) async {
    try {
      await remoteDataSource.deactivateAsistente(userId);
    } catch (e) {
      throw Exception('Error en el repositorio al desactivar asistente: $e');
    }
  }

  @override
  Future<Asistente?> getAsistenteByUserId(String userId) async {
    try {
      final data = await remoteDataSource.fetchAsistenteById(userId);
      return data == null ? null : AsistenteModel.fromJson(data);
    } catch (e) {
      throw Exception('Error en el repositorio al obtener asistente: $e');
    }
  }

  @override
  Future<void> updateAsistente(String userId, String newUserId) async {
    try {
      await remoteDataSource.updateAsistente(userId, newUserId);
    } catch (e) {
      throw Exception('Error en el repositorio al actualizar asistente: $e');
    }
  }
}
