import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/actividad_planificada.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/data/datasources/cita_remote_datasources.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/referencia_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/errors/cancelacion_con_consulta_abierta.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/errors/transicion_estado_invalida.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/consulta_abierta_lookup.dart';

class CitaRepositoryImpl implements CitaRepository {
  final CitaRemoteDataSource remoteDataSource;

  /// Opcional para no romper a quien construya el repositorio sin él (tests
  /// de otras áreas). Sin el lookup no se puede afirmar que la consulta esté
  /// cerrada, así que la cancelación se deja pasar y la última palabra queda
  /// en el trigger `citas_bloquear_cancelacion_con_consulta_abierta`.
  final ConsultaAbiertaLookup? consultaAbiertaLookup;

  CitaRepositoryImpl({
    required this.remoteDataSource,
    this.consultaAbiertaLookup,
  });

  @override
  Future<List<Cita>> getCitas() {
    return runGuarded(
      () => remoteDataSource.fetchCitas(),
      context: 'obtener las citas',
    );
  }

  @override
  Future<List<ActividadPlanificada>> getActividadesAgendables(
    String pacienteId,
  ) {
    return runGuarded(
      () => remoteDataSource.fetchActividadesAgendables(pacienteId),
      context: 'obtener las actividades del plan del paciente',
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
  Future<ReferenciaCita?> getReferenciaCita(String id) {
    return runGuarded(
      () => remoteDataSource.fetchReferenciaCita(id),
      context: 'consultar la cita de origen',
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
    await _rechazarCancelacionConConsultaAbierta(id, nuevoEstado);
    await runGuarded(
      () => remoteDataSource.updateCitaEstado(id, nuevoEstado),
      context: 'actualizar el estado de la cita',
    );
  }

  /// El grafo de estados permite `enConsulta → cancelada` porque una consulta
  /// eliminada sí deja a la cita cancelable. Lo que no se admite es cancelarla
  /// con la consulta todavía abierta: eso es lo que se comprueba aquí.
  Future<void> _rechazarCancelacionConConsultaAbierta(
    String citaId,
    EstadoCita nuevoEstado,
  ) async {
    if (nuevoEstado != EstadoCita.cancelada) return;
    final lookup = consultaAbiertaLookup;
    if (lookup == null) return;

    final abierta = await runGuarded(
      () => lookup.tieneConsultaAbierta(citaId),
      context: 'verificar la consulta de la cita',
    );
    if (abierta) throw const CancelacionConConsultaAbierta();
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
    if (actual != cita.estado) {
      await _rechazarCancelacionConConsultaAbierta(cita.id!, cita.estado);
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
      actividades: cita.actividades,
    );
  }
}
