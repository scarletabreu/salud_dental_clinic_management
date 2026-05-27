import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final CitaRepository _citaRepository;
  final IPacienteRepository _pacienteRepository;
  final IMedicinaRepository _medicinaRepository;

  DashboardCubit({
    required CitaRepository citaRepository,
    required IPacienteRepository pacienteRepository,
    required IMedicinaRepository medicinaRepository,
  })  : _citaRepository = citaRepository,
        _pacienteRepository = pacienteRepository,
        _medicinaRepository = medicinaRepository,
        super(const DashboardLoading());

  Future<void> load() async {
    emit(const DashboardLoading());
    try {
      final now = DateTime.now();

      final citas = await _citaRepository.getCitas();
      final pacientesResult = await _pacienteRepository.getPacientes();
      final medicinas = await _medicinaRepository.getCatalogoMedicinas();

      final citasDeHoy = citas
          .where(
            (c) =>
                c.date.year == now.year &&
                c.date.month == now.month &&
                c.date.day == now.day,
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final citasPendientes =
          citasDeHoy.where((c) => c.estado == EstadoCita.pendiente).length;
      final citasEnEspera =
          citasDeHoy.where((c) => c.estado == EstadoCita.enEspera).length;
      final citasCompletadas =
          citasDeHoy.where((c) => c.estado == EstadoCita.completada).length;

      final totalPacientes =
          pacientesResult.fold((_) => 0, (list) => list.length);

      // Pull doctor name from today's citas, falling back to any cita
      final sourceCita =
          citasDeHoy.isNotEmpty ? citasDeHoy.first : citas.isNotEmpty ? citas.first : null;
      final nombreDoctor =
          sourceCita != null ? 'Dr. ${sourceCita.doctor.apellido}' : null;

      emit(DashboardLoaded(
        citasHoy: citasDeHoy.length,
        citasPendientes: citasPendientes,
        citasEnEspera: citasEnEspera,
        citasCompletadas: citasCompletadas,
        totalPacientes: totalPacientes,
        totalMedicinas: medicinas.length,
        citasDeHoy: citasDeHoy,
        nombreDoctor: nombreDoctor,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> updateEstado(String citaId, EstadoCita nuevoEstado) async {
    final current = state;
    if (current is! DashboardLoaded) return;

    // Optimistic update so UI responds immediately
    final updatedCitas = current.citasDeHoy.map((c) {
      return c.id == citaId ? c.copyWith(estado: nuevoEstado) : c;
    }).toList();

    final pendientes =
        updatedCitas.where((c) => c.estado == EstadoCita.pendiente).length;
    final enEspera =
        updatedCitas.where((c) => c.estado == EstadoCita.enEspera).length;
    final completadas =
        updatedCitas.where((c) => c.estado == EstadoCita.completada).length;

    emit(current.copyWith(
      citasDeHoy: updatedCitas,
      citasPendientes: pendientes,
      citasEnEspera: enEspera,
      citasCompletadas: completadas,
    ));

    try {
      await _citaRepository.updateCitaEstado(citaId, nuevoEstado);
    } catch (_) {
      // Revert to server state on failure
      await load();
    }
  }
}
