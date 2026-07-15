import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/data/datasources/doctor_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/doctor_model.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDatasource remoteDataSource;

  DoctorRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> createDoctor(String userId) {
    return runGuarded(
      () => remoteDataSource.createDoctor(userId),
      context: 'crear el doctor',
    );
  }

  @override
  Future<void> deleteDoctor(String userId) {
    return runGuarded(
      () => remoteDataSource.deactivateDoctor(userId),
      context: 'desactivar el doctor',
    );
  }

  @override
  Future<void> updateDoctor(String userId, String newUserId) {
    return runGuarded(
      () => remoteDataSource.updateDoctor(userId, newUserId),
      context: 'actualizar el doctor',
    );
  }

  @override
  Future<List<Doctor>> getDoctores() {
    return runGuarded(
      () => remoteDataSource.fetchActiveDoctores(),
      context: 'obtener los doctores',
    );
  }

  @override
  Future<Doctor?> getDoctorByUserId(String userId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchDoctorById(userId);
      return data == null ? null : DoctorModel.fromJson(data);
    }, context: 'obtener el doctor');
  }
}
