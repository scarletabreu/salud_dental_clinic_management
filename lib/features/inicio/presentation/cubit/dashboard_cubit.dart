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

      final citasEnEspera =
          citasDeHoy.where((c) => c.estado == EstadoCita.enEspera).length;
      final citasCompletadas =
          citasDeHoy.where((c) => c.estado == EstadoCita.completada).length;

      final totalPacientes =
          pacientesResult.fold((_) => 0, (list) => list.length);

      emit(DashboardLoaded(
        citasHoy: citasDeHoy.length,
        citasEnEspera: citasEnEspera,
        citasCompletadas: citasCompletadas,
        totalPacientes: totalPacientes,
        totalMedicinas: medicinas.length,
        citasDeHoy: citasDeHoy,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
