import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/data/datasources/cita_remote_datasources.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';

class CitaRepositoryImpl implements CitaRepository {
  final CitaRemoteDataSource remoteDataSource;

  CitaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Cita>> getCitas() async {
    return await remoteDataSource.fetchCitas();
  }

  @override
  Future<void> createCita(Cita cita) async {
    if (cita.date.isBefore(DateTime.now())) {
      throw Exception("No se puede programar una cita en el pasado");
    }

    final model = CitaModel(
      doctor: cita.doctor,
      persona: cita.persona,
      date: cita.date,
      esEmergencia: cita.esEmergencia,
      estado: cita.estado,
    );

    await remoteDataSource.addCita(model);
  }

  @override
  Future<List<Cita>> getCitasByPaciente(String pacienteId) {
    return remoteDataSource.fetchCitasByPaciente(pacienteId);
  }

  @override
  Future<void> deleteCita(String id) async {
    await remoteDataSource.deleteCita(id);
  }
}
