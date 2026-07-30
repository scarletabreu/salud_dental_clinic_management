import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/data/datasources/doctor_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/doctor_model.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDatasource remoteDataSource;

  DoctorRepositoryImpl(this.remoteDataSource);

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

  // data/repositories/doctor_repository_impl.dart
  @override
  Future<List<String>> getDoctorIdsAsignados(String asistenteId) {
    return runGuarded(() async {
      final rows = await remoteDataSource.fetchDoctorAsistentesByAsistenteId(
        asistenteId,
      );
      return rows.map((row) => row['doctor_id'].toString()).toList();
    }, context: 'obtener los doctores asignados al asistente');
  }
}
