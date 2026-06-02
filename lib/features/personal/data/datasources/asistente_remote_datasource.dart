abstract class AsistenteRemoteDatasource {
  Future<void> createAsistente(String userId);
  Future<List<String>> fetchAsistenteUserIds();
  Future<bool> isAsistente(String userId);
  Future<void> updateAsistente(String userId, String newUserId);
  Future<void> deactivateAsistente(String userId);
  Future<void> reactivateAsistente(String userId);
  Future<Map<String, dynamic>?> fetchAsistenteById(String userId);
}
