import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/asistente_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/data/datasources/asistente_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/asistente_model.dart';

class AsistenteRepositoryImpl implements AsistenteRepository {
  final AsistenteRemoteDatasource remoteDataSource;

  AsistenteRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> createAsistente(String userId) {
    return runGuarded(
      () => remoteDataSource.createAsistente(userId),
      context: 'crear el asistente',
    );
  }

  @override
  Future<void> deleteAsistente(String userId) {
    return runGuarded(
      () => remoteDataSource.deactivateAsistente(userId),
      context: 'desactivar el asistente',
    );
  }

  @override
  Future<Asistente?> getAsistenteByUserId(String userId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchAsistenteById(userId);
      return data == null ? null : AsistenteModel.fromJson(data);
    }, context: 'obtener el asistente');
  }

  @override
  Future<void> updateAsistente(String userId, String newUserId) {
    return runGuarded(
      () => remoteDataSource.updateAsistente(userId, newUserId),
      context: 'actualizar el asistente',
    );
  }
}
