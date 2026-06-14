import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/data/datasources/cita_remote_datasources.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/errors/transicion_estado_invalida.dart';
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
        duracionMinutos: cita.duracionMinutos,
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
  Future<List<Cita>> getCitasByDoctor(String doctorId) async {
    try {
      return await remoteDataSource.fetchCitasByDoctor(doctorId);
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener citas del doctor: $e',
      );
    }
  }

  @override
  Future<void> updateCitaEstado(String id, EstadoCita nuevoEstado) async {
    final actual = await remoteDataSource.fetchEstadoCita(id);
    // `actual == null` => la cita no existe en BD (datos de prueba): no validamos.
    if (actual != null && !actual.puedeTransicionarA(nuevoEstado)) {
      throw TransicionEstadoInvalida(actual, nuevoEstado);
    }
    try {
      await remoteDataSource.updateCitaEstado(id, nuevoEstado);
    } catch (e) {
      throw Exception(
        'Error en el repositorio al actualizar el estado de la cita: $e',
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

  @override
  Future<void> updateCita(Cita cita) async {
    if (cita.id == null) {
      throw Exception("No se puede actualizar una cita sin un ID válido");
    }

    // Si la actualización cambia el estado, validar la transición.
    final actual = await remoteDataSource.fetchEstadoCita(cita.id!);
    if (actual != null &&
        actual != cita.estado &&
        !actual.puedeTransicionarA(cita.estado)) {
      throw TransicionEstadoInvalida(actual, cita.estado);
    }

    try {
      final model = CitaModel(
        id: cita.id,
        doctor: cita.doctor,
        persona: cita.persona,
        date: cita.date,
        duracionMinutos: cita.duracionMinutos,
        esEmergencia: cita.esEmergencia,
        estado: cita.estado,
      );

      await remoteDataSource.updateCita(model);
    } catch (e) {
      throw Exception('Error en el repositorio al actualizar la cita: $e');
    }
  }
}
