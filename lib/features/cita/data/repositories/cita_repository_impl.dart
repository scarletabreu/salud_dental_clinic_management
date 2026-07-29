import 'package:salud_dental_clinic_management/core/errors/guard.dart';
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
  Future<List<Cita>> getCitas() {
    return runGuarded(
      () => remoteDataSource.fetchCitas(),
      context: 'obtener las citas',
    );
  }

  @override
  Future<void> createCita(Cita cita) {
    // Validación de dominio fuera del guard para conservar su mensaje.
    if (cita.date.isBefore(DateTime.now())) {
      throw Exception('No se puede programar una cita en el pasado');
    }
    return runGuarded(
      () => remoteDataSource.addCita(_toModel(cita)),
      context: 'crear la cita',
    );
  }

  @override
  Future<List<Cita>> getCitasByPaciente(String pacienteId) {
    return runGuarded(
      () => remoteDataSource.fetchCitasByPaciente(pacienteId),
      context: 'obtener las citas del paciente',
    );
  }

  @override
  Future<List<Cita>> getCitasByDoctor(String doctorId) {
    return runGuarded(
      () => remoteDataSource.fetchCitasByDoctor(doctorId),
      context: 'obtener las citas del doctor',
    );
  }

  @override
  Future<void> updateCitaEstado(String id, EstadoCita nuevoEstado) async {
    final actual = await runGuarded(
      () => remoteDataSource.fetchEstadoCita(id),
      context: 'consultar el estado de la cita',
    );
    if (!actual.puedeTransicionarA(nuevoEstado)) {
      throw TransicionEstadoInvalida(actual, nuevoEstado);
    }
    await runGuarded(
      () => remoteDataSource.updateCitaEstado(id, nuevoEstado),
      context: 'actualizar el estado de la cita',
    );
  }

  @override
  Future<void> deleteCita(String id) {
    return runGuarded(
      () => remoteDataSource.deleteCita(id),
      context: 'eliminar la cita',
    );
  }

  @override
  Future<void> updateCita(Cita cita) async {
    if (cita.id == null) {
      throw Exception('No se puede actualizar una cita sin un ID válido');
    }

    // Si la actualización cambia el estado, validar la transición.
    final actual = await runGuarded(
      () => remoteDataSource.fetchEstadoCita(cita.id!),
      context: 'consultar el estado de la cita',
    );
    if (actual != cita.estado && !actual.puedeTransicionarA(cita.estado)) {
      throw TransicionEstadoInvalida(actual, cita.estado);
    }

    await runGuarded(
      () => remoteDataSource.updateCita(_toModel(cita)),
      context: 'actualizar la cita',
    );
  }

  CitaModel _toModel(Cita cita) {
    return CitaModel(
      id: cita.id,
      doctor: cita.doctor,
      persona: cita.persona,
      date: cita.date,
      duracionMinutos: cita.duracionMinutos,
      esEmergencia: cita.esEmergencia,
      estado: cita.estado,
      motivo: cita.motivo,
    );
  }
}
