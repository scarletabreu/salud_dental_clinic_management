abstract class DoctorRemoteDatasource {
  Future<void> createDoctor(String userId);
  Future<List<String>> fetchDoctorUserIds();
  Future<bool> isDoctor(String userId);
  Future<void> updateDoctor(String userId, String newUserId);
  Future<void> deactivateDoctor(String userId);
  Future<void> reactivateDoctor(String userId);
  Future<Map<String, dynamic>?> fetchDoctorById(String userId);
}
