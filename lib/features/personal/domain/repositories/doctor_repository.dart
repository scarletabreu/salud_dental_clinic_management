import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

abstract class DoctorRepository {
  Future<void> createDoctor(String userId);
  Future<void> updateDoctor(String userId, String newUserId);
  Future<void> deleteDoctor(String userId);
  Future<Doctor?> getDoctorByUserId(String userId);
}
