import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/eliminar_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'consultas_list_state.dart';

class ConsultasListCubit extends Cubit<ConsultasListState> {
  final ConsultaRepository _consultaRepository;
  final IPacienteRepository _pacienteRepository;
  final DoctorRepository _doctorRepository;
  final EliminarConsultaUseCase _eliminarConsultaUseCase;

  ConsultasListCubit({
    required ConsultaRepository consultaRepository,
    required IPacienteRepository pacienteRepository,
    required DoctorRepository doctorRepository,
    required EliminarConsultaUseCase eliminarConsultaUseCase,
  }) : _consultaRepository = consultaRepository,
       _pacienteRepository = pacienteRepository,
       _doctorRepository = doctorRepository,
       _eliminarConsultaUseCase = eliminarConsultaUseCase,
       super(const ConsultasInitial());

  String? _restringidoADoctorId;

  Future<void> recargar() =>
      cargar(restringidoADoctorId: _restringidoADoctorId);

  Future<void> cargar({
    String? pacienteId,
    String? doctorId,
    DateTimeRange? rangoFechas,
    String? restringidoADoctorId,
  }) async {
    _restringidoADoctorId = restringidoADoctorId;
    emit(const ConsultasLoading());
    try {
      final consultas = restringidoADoctorId != null
          ? await _consultaRepository.getConsultasByDoctor(restringidoADoctorId)
          : await _consultaRepository.getConsultas();
      final doctores = await _cargarDoctores();

      // Los nombres salen del directorio, no del listado de pacientes: con el
      // modelo de permisos de producción un doctor ve consultas de pacientes
      // cuya ficha no puede abrir, y antes esas filas caían al `Paciente
      // #uuid` (defecto D4). Un fallo aquí **se propaga**: antes se tragaba
      // con un `fold((_) => [])` y el usuario veía uuids sin saber por qué.
      final ids = consultas.map((c) => c.pacienteId).toSet().toList();
      final pacienteNombres = await _cargarNombresPacientes(ids);
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
    final updated = current.copyWith(busquedaPaciente: query);
    emit(updated.copyWith(filtradas: _filtrarDesde(updated)));
  }

  void filtrarPorDoctor(String? doctorId) {
    final current = state;
    if (current is! ConsultasLoaded) return;
    final updated = current.copyWith(doctorIdFiltro: doctorId);
    emit(updated.copyWith(filtradas: _filtrarDesde(updated)));
  }

  void filtrarPorRango(DateTimeRange? rango) {
    final current = state;
    if (current is! ConsultasLoaded) return;
    final updated = current.copyWith(rangoFechas: rango);
    emit(updated.copyWith(filtradas: _filtrarDesde(updated)));
  }

  void aplicarFiltrosAvanzados({
    bool? finalizada,
    bool? tieneNotas,
    bool? tieneOdontograma,
    bool? tieneRecetas,
    bool? tieneTratamientos,
    bool? soloEmergencias,
  }) {
    final current = state;
    if (current is! ConsultasLoaded) return;

    final newState = current.copyWith(
      finalizada: finalizada,
      tieneNotas: tieneNotas,
      tieneOdontograma: tieneOdontograma,
      tieneRecetas: tieneRecetas,
      tieneTratamientos: tieneTratamientos,
      soloEmergencias: soloEmergencias,
    );

    emit(newState.copyWith(filtradas: _filtrarDesde(newState)));
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

  Future<void> eliminarConsulta(Consulta consulta) async {
    try {
      await _eliminarConsultaUseCase(consulta);
      await recargar();
    } catch (e) {
      emit(ConsultasError(_mensajeError(e)));
    }
  }

  Future<Map<String, String>> _cargarNombresPacientes(List<String> ids) async {
    final result = await _pacienteRepository.getNombresPacientes(ids);
    return result.fold((failure) => throw failure, (nombres) => nombres);
  }

  Future<List<Doctor>> _cargarDoctores() async {
    try {
      return await _doctorRepository.getDoctores();
    } catch (_) {
      return <Doctor>[];
    }
  }

  List<Consulta> _filtrarDesde(ConsultasLoaded current) {
    return _filtrar(
      current.todas,
      busqueda: current.busquedaPaciente,
      doctorId: current.doctorIdFiltro,
      rango: current.rangoFechas,
      finalizada: current.finalizada,
      tieneNotas: current.tieneNotas,
      tieneOdontograma: current.tieneOdontograma,
      tieneRecetas: current.tieneRecetas,
      tieneTratamientos: current.tieneTratamientos,
      soloEmergencias: current.soloEmergencias,
      pacienteNombres: current.pacienteNombres,
    );
  }

  List<Consulta> _filtrar(
    List<Consulta> base, {
    required String busqueda,
    String? doctorId,
    DateTimeRange? rango,
    bool? finalizada,
    bool? tieneNotas,
    bool? tieneOdontograma,
    bool? tieneRecetas,
    bool? tieneTratamientos,
    bool? soloEmergencias,
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

    if (finalizada != null) {
      resultado = resultado.where((c) => c.finalizada == finalizada);
    }

    if (tieneNotas != null) {
      resultado = resultado.where((c) {
        final hasNotas = c.notas != null && c.notas!.trim().isNotEmpty;
        return hasNotas == tieneNotas;
      });
    }

    if (tieneOdontograma != null) {
      resultado = resultado.where(
        (c) => (c.odontograma != null) == tieneOdontograma,
      );
    }

    if (tieneRecetas != null) {
      resultado = resultado.where((c) => c.tieneRecetas == tieneRecetas);
    }

    if (tieneTratamientos != null) {
      resultado = resultado.where(
        (c) => c.tieneTratamientosAplicados == tieneTratamientos,
      );
    }

    if (soloEmergencias != null && soloEmergencias == true) {
      resultado = resultado.where((c) {
        try {
          final dynamic obj = c;
          return obj.esEmergencia == true;
        } catch (_) {
          return c.motivoConsulta?.toLowerCase().contains('emergencia') == true;
        }
      });
    }

    return resultado.toList();
  }

  String _mensajeError(Object e) {
    final raw = e.toString();
    return raw.replaceFirst('Exception: ', '');
  }
}
