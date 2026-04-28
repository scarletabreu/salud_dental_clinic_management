import 'package:salud_dental_clinic_management/features/personal/data/datasources/asistente_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/asistente_model.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/asistente_repository.dart';

class AsistenteRepositoryImpl implements AsistenteRepository {
  final AsistenteRemoteDatasource remoteDataSource;

  AsistenteRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> createAsistente(String userId) async {
    await remoteDataSource.createAsistente(userId);
  }

  @override
  Future<void> deleteAsistente(String userId) async {
    await remoteDataSource.deactivateAsistente(userId);
  }

  @override
  Future<Asistente?> getAsistenteByUserId(String userId) async {
    final data = await remoteDataSource.fetchAsistenteById(userId);

    if (data == null) return null;
    return AsistenteModel.fromJson(data);
  }

  @override
  Future<void> updateAsistente(String userId, String newUserId) async {
    await remoteDataSource.updateAsistente(userId, newUserId);
  }
}
