import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/data/datasources/doctor_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/doctor_model.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDatasource remoteDataSource;

  DoctorRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> createDoctor(String userId) async {
    try {
      await remoteDataSource.createDoctor(userId);
    } catch (e) {
      throw Exception('Error en el repositorio al crear doctor: $e');
    }
  }

  @override
  Future<void> deleteDoctor(String userId) async {
    try {
      await remoteDataSource.deactivateDoctor(userId);
    } catch (e) {
      throw Exception('Error en el repositorio al desactivar doctor: $e');
    }
  }

  @override
  Future<void> updateDoctor(String userId, String newUserId) async {
    try {
      await remoteDataSource.updateDoctor(userId, newUserId);
    } catch (e) {
      throw Exception('Error en el repositorio al actualizar doctor: $e');
    }
  }

  @override
  Future<Doctor?> getDoctorByUserId(String userId) async {
    try {
      final data = await remoteDataSource.fetchDoctorById(userId);
      return data == null ? null : DoctorModel.fromJson(data);
    } catch (e) {
      throw Exception('Error en el repositorio al obtener doctor: $e');
    }
  }
}
