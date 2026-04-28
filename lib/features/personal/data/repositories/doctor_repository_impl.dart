import 'package:salud_dental_clinic_management/features/personal/data/datasources/doctor_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/doctor_model.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDatasource remoteDataSource;

  DoctorRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> createDoctor(String userId) async {
    await remoteDataSource.createDoctor(userId);
  }

  @override
  Future<void> deleteDoctor(String userId) async {
    await remoteDataSource.deactivateDoctor(userId);
  }

  @override
  Future<void> updateDoctor(String userId, String newUserId) async {
    await remoteDataSource.updateDoctor(userId, newUserId);
  }

  @override
  Future<Doctor?> getDoctorByUserId(String userId) async {
    final data = await remoteDataSource.fetchDoctorById(userId);
    if (data == null) return null;
    return DoctorModel.fromJson(data);
  }
}
