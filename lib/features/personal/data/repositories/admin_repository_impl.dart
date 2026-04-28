import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/admin_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/data/datasources/admin_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/admin_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDatasource remoteDataSource;

  AdminRepositoryImpl(this.remoteDataSource);

  @override
  Future<Admin?> getAdminByUserId(String userId) async {
    final data = await remoteDataSource.fetchAdminById(userId);

    if (data == null) return null;

    return AdminModel.fromJson(data);
  }

  @override
  Future<void> createAdmin(String userId) async {
    await remoteDataSource.createAdmin(userId);
  }

  @override
  Future<void> updateAdmin(String userId, String newUserId) async {
    await remoteDataSource.updateAdmin(userId, newUserId);
  }

  @override
  Future<void> deleteAdmin(String userId) async {
    await remoteDataSource.deactivateAdmin(userId);
  }
}
