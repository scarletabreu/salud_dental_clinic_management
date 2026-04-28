import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';

abstract class AdminRepository {
  Future<void> createAdmin(String userId);
  Future<void> updateAdmin(String userId, String newUserId);
  Future<void> deleteAdmin(String userId);
  Future<Admin?> getAdminByUserId(String userId);
}
