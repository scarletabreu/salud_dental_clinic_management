import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

/// Consulta del catálogo clínico. El alta y la baja de un doctor pasan por la
/// Edge Function de creación de usuarios, no por este repositorio.
abstract class DoctorRepository {
  Future<List<Doctor>> getDoctores();
  Future<Doctor?> getDoctorByUserId(String userId);
  Future<List<String>> getDoctorIdsAsignados(String asistenteId);
}
