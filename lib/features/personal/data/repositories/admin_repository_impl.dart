import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/admin_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/data/datasources/admin_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/admin_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDatasource remoteDataSource;

  AdminRepositoryImpl(this.remoteDataSource);

  @override
  Future<Admin?> getAdminByUserId(String userId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchAdminById(userId);
      return data == null ? null : AdminModel.fromJson(data);
    }, context: 'obtener el admin');
  }

  @override
  Future<void> createAdmin(String userId) {
    return runGuarded(
      () => remoteDataSource.createAdmin(userId),
      context: 'crear el admin',
    );
  }

  @override
  Future<void> updateAdmin(String userId, String newUserId) {
    return runGuarded(
      () => remoteDataSource.updateAdmin(userId, newUserId),
      context: 'actualizar el admin',
    );
  }

  @override
  Future<void> deleteAdmin(String userId) {
    return runGuarded(
      () => remoteDataSource.deactivateAdmin(userId),
      context: 'desactivar el admin',
    );
  }
}
