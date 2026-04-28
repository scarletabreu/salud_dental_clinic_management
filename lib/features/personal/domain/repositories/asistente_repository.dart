import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';

abstract class AsistenteRepository {
  Future<void> createAsistente(String userId);
  Future<void> updateAsistente(String userId, String newUserId);
  Future<void> deleteAsistente(String userId);
  Future<Asistente?> getAsistenteByUserId(String userId);
}
