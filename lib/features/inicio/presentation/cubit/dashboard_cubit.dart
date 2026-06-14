import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final CitaRepository _citaRepository;
  final IPacienteRepository _pacienteRepository;
  final IMedicinaRepository _medicinaRepository;

  List<RolUsuario> _roles = const [];
  String? _doctorId;
  String? _doctorName;

  DashboardCubit({
    required CitaRepository citaRepository,
    required IPacienteRepository pacienteRepository,
    required IMedicinaRepository medicinaRepository,
  }) : _citaRepository = citaRepository,
       _pacienteRepository = pacienteRepository,
       _medicinaRepository = medicinaRepository,
       super(const DashboardLoading());

  Future<void> load({
    required List<RolUsuario> roles,
    String? doctorId,
    String? doctorName,
  }) async {
    emit(const DashboardLoading());
    try {
      _roles = roles;
      _doctorId = doctorId;
      _doctorName = doctorName;

      final now = DateTime.now();
      final isAdmin = roles.contains(RolUsuario.admin);
      final isDoctor = roles.contains(RolUsuario.doctor);

      final citas = (isDoctor && doctorId != null)
          ? await _citaRepository.getCitasByDoctor(doctorId)
          : await _citaRepository.getCitas();

      final pacientesResult = await _pacienteRepository.getPacientes();
      final totalPacientes = pacientesResult.fold(
        (_) => 0,
        (list) => list.length,
      );

      final medicinas = (isAdmin || isDoctor)
          ? await _medicinaRepository.getCatalogoMedicinas()
          : <dynamic>[];

      final citasDeHoy =
          citas
              .where(
                (c) =>
                    c.date.year == now.year &&
                    c.date.month == now.month &&
                    c.date.day == now.day,
              )
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

      emit(
        DashboardLoaded(
          roles: roles,
          nombreDoctor: isDoctor ? doctorName : null,
          citasHoy: citasDeHoy.length,
          citasPendientes: citasDeHoy
              .where((c) => c.estado == EstadoCita.programada)
              .length,
          citasEnEspera: citasDeHoy
              .where((c) => c.estado == EstadoCita.enEspera)
              .length,
          citasCompletadas: citasDeHoy
              .where((c) => c.estado == EstadoCita.completada)
              .length,
          totalPacientes: totalPacientes,
          totalMedicinas: medicinas.length,
          citasDeHoy: citasDeHoy,
        ),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> updateEstado(String citaId, EstadoCita nuevoEstado) async {
    final current = state;
    if (current is! DashboardLoaded) return;

    final updatedCitas = current.citasDeHoy
        .map((c) => c.id == citaId ? c.copyWith(estado: nuevoEstado) : c)
        .toList();

    emit(
      current.copyWith(
        citasDeHoy: updatedCitas,
        citasPendientes: updatedCitas
            .where((c) => c.estado == EstadoCita.programada)
            .length,
        citasEnEspera: updatedCitas
            .where((c) => c.estado == EstadoCita.enEspera)
            .length,
        citasCompletadas: updatedCitas
            .where((c) => c.estado == EstadoCita.completada)
            .length,
      ),
    );

    try {
      await _citaRepository.updateCitaEstado(citaId, nuevoEstado);
    } catch (_) {
      await load(roles: _roles, doctorId: _doctorId, doctorName: _doctorName);
    }
  }
}
