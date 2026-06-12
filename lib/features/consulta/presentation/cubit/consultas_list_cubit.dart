import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'consultas_list_state.dart';

class ConsultasListCubit extends Cubit<ConsultasListState> {
  final ConsultaRepository _consultaRepository;
  final IPacienteRepository _pacienteRepository;
  final DoctorRepository _doctorRepository;

  ConsultasListCubit({
    required ConsultaRepository consultaRepository,
    required IPacienteRepository pacienteRepository,
    required DoctorRepository doctorRepository,
  }) : _consultaRepository = consultaRepository,
       _pacienteRepository = pacienteRepository,
       _doctorRepository = doctorRepository,
       super(const ConsultasInitial());

  /// Restricción aplicada en la última carga (doctor logueado); se conserva
  /// para poder recargar el listado sin perderla.
  String? _restringidoADoctorId;

  /// Recarga el listado conservando la restricción por doctor.
  Future<void> recargar() =>
      cargar(restringidoADoctorId: _restringidoADoctorId);

  /// Carga el listado completo de consultas junto con los nombres de pacientes
  /// y doctores. Permite además aplicar filtros iniciales.
  Future<void> cargar({
    String? pacienteId,
    String? doctorId,
    DateTimeRange? rangoFechas,
    String? restringidoADoctorId,
  }) async {
    _restringidoADoctorId = restringidoADoctorId;
    emit(const ConsultasLoading());
    try {
      var consultas = await _consultaRepository.getConsultas();
      // Un doctor solo ve sus propias consultas: restringimos la base y
      // ocultamos el filtro por doctor.
      if (restringidoADoctorId != null) {
        consultas = consultas
            .where((c) => c.doctorId == restringidoADoctorId)
            .toList();
      }
      final pacientes = await _cargarPacientes();
      final doctores = await _cargarDoctores();

      final pacienteNombres = <String, String>{
        for (final p in pacientes)
          if (p.id != null) p.id!: p.fullName,
      };
      final doctorNombres = <String, String>{
        for (final d in doctores)
          if (d.id != null) d.id!: d.fullName,
      };

      final busqueda = pacienteId != null
          ? (pacienteNombres[pacienteId] ?? '')
          : '';

      final filtradas = _filtrar(
        consultas,
        busqueda: busqueda,
        doctorId: doctorId,
        rango: rangoFechas,
        pacienteNombres: pacienteNombres,
      );

      emit(
        ConsultasLoaded(
          todas: consultas,
          filtradas: filtradas,
          pacienteNombres: pacienteNombres,
          doctorNombres: doctorNombres,
          doctores: doctores,
          puedeFiltrarPorDoctor: restringidoADoctorId == null,
          busquedaPaciente: busqueda,
          doctorIdFiltro: doctorId,
          rangoFechas: rangoFechas,
        ),
      );
    } catch (e) {
      emit(ConsultasError(_mensajeError(e)));
    }
  }

  void buscarPaciente(String query) {
    final current = state;
    if (current is! ConsultasLoaded) return;
    emit(
      current.copyWith(
        busquedaPaciente: query,
        filtradas: _filtrarDesde(current, busqueda: query),
      ),
    );
  }

  void filtrarPorDoctor(String? doctorId) {
    final current = state;
    if (current is! ConsultasLoaded) return;
    emit(
      current.copyWith(
        doctorIdFiltro: () => doctorId,
        filtradas: _filtrarDesde(current, doctorId: () => doctorId),
      ),
    );
  }

  void filtrarPorRango(DateTimeRange? rango) {
    final current = state;
    if (current is! ConsultasLoaded) return;
    emit(
      current.copyWith(
        rangoFechas: () => rango,
        filtradas: _filtrarDesde(current, rango: () => rango),
      ),
    );
  }

  void limpiarFiltros() {
    final current = state;
    if (current is! ConsultasLoaded) return;
    emit(
      ConsultasLoaded(
        todas: current.todas,
        filtradas: List.of(current.todas),
        pacienteNombres: current.pacienteNombres,
        doctorNombres: current.doctorNombres,
        doctores: current.doctores,
        puedeFiltrarPorDoctor: current.puedeFiltrarPorDoctor,
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Future<List<Paciente>> _cargarPacientes() async {
    final result = await _pacienteRepository.getPacientes();
    return result.fold((_) => <Paciente>[], (list) => list);
  }

  Future<List<Doctor>> _cargarDoctores() async {
    try {
      return await _doctorRepository.getDoctores();
    } catch (_) {
      return <Doctor>[];
    }
  }

  /// Reaplica los filtros tomando los valores actuales del estado, salvo los
  /// que se sobreescriban explícitamente.
  List<Consulta> _filtrarDesde(
    ConsultasLoaded current, {
    String? busqueda,
    String? Function()? doctorId,
    DateTimeRange? Function()? rango,
  }) {
    return _filtrar(
      current.todas,
      busqueda: busqueda ?? current.busquedaPaciente,
      doctorId: doctorId != null ? doctorId() : current.doctorIdFiltro,
      rango: rango != null ? rango() : current.rangoFechas,
      pacienteNombres: current.pacienteNombres,
    );
  }

  List<Consulta> _filtrar(
    List<Consulta> base, {
    required String busqueda,
    String? doctorId,
    DateTimeRange? rango,
    required Map<String, String> pacienteNombres,
  }) {
    Iterable<Consulta> resultado = base;

    final q = busqueda.toLowerCase().trim();
    if (q.isNotEmpty) {
      resultado = resultado.where(
        (c) => (pacienteNombres[c.pacienteId] ?? '').toLowerCase().contains(q),
      );
    }

    if (doctorId != null) {
      resultado = resultado.where((c) => c.doctorId == doctorId);
    }

    if (rango != null) {
      final inicio = DateTime(
        rango.start.year,
        rango.start.month,
        rango.start.day,
      );
      final fin = DateTime(
        rango.end.year,
        rango.end.month,
        rango.end.day,
        23,
        59,
        59,
      );
      resultado = resultado.where(
        (c) => !c.fecha.isBefore(inicio) && !c.fecha.isAfter(fin),
      );
    }

    return resultado.toList();
  }

  String _mensajeError(Object e) {
    final raw = e.toString();
    return raw.replaceFirst('Exception: ', '');
  }
}
