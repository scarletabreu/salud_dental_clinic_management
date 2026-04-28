abstract class AdminRemoteDatasource {
  Future<void> createAdmin(String userId);
  Future<List<String>> fetchAdminUserIds();
  Future<bool> isAdmin(String userId);
  Future<Map<String, dynamic>?> fetchAdminById(String userId);
  Future<void> updateAdmin(String userId, String newUserId);
  Future<void> deactivateAdmin(String userId);
  Future<void> reactivateAdmin(String userId);
}
