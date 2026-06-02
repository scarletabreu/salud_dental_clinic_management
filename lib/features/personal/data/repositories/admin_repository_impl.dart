import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/admin_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/data/datasources/admin_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/admin_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDatasource remoteDataSource;

  AdminRepositoryImpl(this.remoteDataSource);

  @override
  Future<Admin?> getAdminByUserId(String userId) async {
    try {
      final data = await remoteDataSource.fetchAdminById(userId);
      return data == null ? null : AdminModel.fromJson(data);
    } catch (e) {
      throw Exception('Error en el repositorio al obtener admin: $e');
    }
  }

  @override
  Future<void> createAdmin(String userId) async {
    try {
      await remoteDataSource.createAdmin(userId);
    } catch (e) {
      throw Exception('Error en el repositorio al crear admin: $e');
    }
  }

  @override
  Future<void> updateAdmin(String userId, String newUserId) async {
    try {
      await remoteDataSource.updateAdmin(userId, newUserId);
    } catch (e) {
      throw Exception('Error en el repositorio al actualizar admin: $e');
    }
  }

  @override
  Future<void> deleteAdmin(String userId) async {
    try {
      await remoteDataSource.deactivateAdmin(userId);
    } catch (e) {
      throw Exception('Error en el repositorio al desactivar admin: $e');
    }
  }
}
