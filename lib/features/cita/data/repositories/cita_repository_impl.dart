import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/data/datasources/cita_remote_datasources.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';

class CitaRepositoryImpl implements CitaRepository {
  final CitaRemoteDataSource remoteDataSource;

  CitaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Cita>> getCitas() async {
    try {
      return await remoteDataSource.fetchCitas();
    } catch (e) {
      throw Exception('Error en el repositorio al obtener citas: $e');
    }
  }

  @override
  Future<void> createCita(Cita cita) async {
    try {
      if (cita.date.isBefore(DateTime.now())) {
        throw Exception("No se puede programar una cita en el pasado");
      }

      final model = CitaModel(
        id: cita.id,
        doctor: cita.doctor,
        persona: cita.persona,
        date: cita.date,
        esEmergencia: cita.esEmergencia,
        estado: cita.estado,
      );

      await remoteDataSource.addCita(model);
    } catch (e) {
      throw Exception('Error en el repositorio al crear cita: $e');
    }
  }

  @override
  Future<List<Cita>> getCitasByPaciente(String pacienteId) async {
    try {
      return await remoteDataSource.fetchCitasByPaciente(pacienteId);
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener citas del paciente: $e',
      );
    }
  }

  @override
  Future<void> deleteCita(String id) async {
    try {
      await remoteDataSource.deleteCita(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar cita: $e');
    }
  }
}
