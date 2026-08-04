import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

abstract class ConsultasListState extends Equatable {
  const ConsultasListState();

  @override
  List<Object?> get props => [];
}

class ConsultasInitial extends ConsultasListState {
  const ConsultasInitial();
}

class ConsultasLoading extends ConsultasListState {
  const ConsultasLoading();
}

class ConsultasLoaded extends ConsultasListState {
  final List<Consulta> todas;
  final List<Consulta> filtradas;
  final List<Doctor> doctores;
  final Map<String, String> pacienteNombres;
  final Map<String, String> doctorNombres;
  final bool puedeFiltrarPorDoctor;
  final String busquedaPaciente;
  final String? doctorIdFiltro;
  final DateTimeRange? rangoFechas;

  final bool? finalizada;
  final bool? tieneNotas;
  final bool? tieneOdontograma;
  final bool? tieneRecetas;
  final bool? tieneTratamientos;
  final bool? soloEmergencias;

  const ConsultasLoaded({
    required this.todas,
    required this.filtradas,
    required this.doctores,
    this.pacienteNombres = const {},
    this.doctorNombres = const {},
    this.puedeFiltrarPorDoctor = true,
    this.busquedaPaciente = '',
    this.doctorIdFiltro,
    this.rangoFechas,
    this.finalizada,
    this.tieneNotas,
    this.tieneOdontograma,
    this.tieneRecetas,
    this.tieneTratamientos,
    this.soloEmergencias,
  });

  bool get hayFiltrosActivos =>
      busquedaPaciente.isNotEmpty ||
      doctorIdFiltro != null ||
      rangoFechas != null ||
      finalizada != null ||
      tieneNotas != null ||
      tieneOdontograma != null ||
      tieneRecetas != null ||
      tieneTratamientos != null ||
      soloEmergencias != null;

  /// Si el directorio no trae el nombre, el paciente ya no está ahí (ficha
  /// borrada, o id huérfano). Enseñar el uuid no le dice nada a nadie; decirlo
  /// en palabras sí.
  String nombrePaciente(String pacienteId) {
    return pacienteNombres[pacienteId] ?? 'Paciente no encontrado';
  }

  String nombreDoctor(String doctorId) {
    if (doctorNombres.containsKey(doctorId)) {
      return doctorNombres[doctorId]!;
    }
    final d = doctores.where((doc) => doc.id == doctorId).firstOrNull;
    return d != null ? 'Dr. ${d.nombre} ${d.apellido}' : 'Doctor asignado';
  }

  ConsultasLoaded copyWith({
    List<Consulta>? todas,
    List<Consulta>? filtradas,
    List<Doctor>? doctores,
    Map<String, String>? pacienteNombres,
    Map<String, String>? doctorNombres,
    bool? puedeFiltrarPorDoctor,
    String? busquedaPaciente,
    Object? doctorIdFiltro = _absent,
    Object? rangoFechas = _absent,
    Object? finalizada = _absent,
    Object? tieneNotas = _absent,
    Object? tieneOdontograma = _absent,
    Object? tieneRecetas = _absent,
    Object? tieneTratamientos = _absent,
    Object? soloEmergencias = _absent,
  }) {
    return ConsultasLoaded(
      todas: todas ?? this.todas,
      filtradas: filtradas ?? this.filtradas,
      doctores: doctores ?? this.doctores,
      pacienteNombres: pacienteNombres ?? this.pacienteNombres,
      doctorNombres: doctorNombres ?? this.doctorNombres,
      puedeFiltrarPorDoctor:
          puedeFiltrarPorDoctor ?? this.puedeFiltrarPorDoctor,
      busquedaPaciente: busquedaPaciente ?? this.busquedaPaciente,
      doctorIdFiltro: doctorIdFiltro == _absent
          ? this.doctorIdFiltro
          : doctorIdFiltro as String?,
      rangoFechas: rangoFechas == _absent
          ? this.rangoFechas
          : rangoFechas as DateTimeRange?,
      finalizada: finalizada == _absent ? this.finalizada : finalizada as bool?,
      tieneNotas: tieneNotas == _absent ? this.tieneNotas : tieneNotas as bool?,
      tieneOdontograma: tieneOdontograma == _absent
          ? this.tieneOdontograma
          : tieneOdontograma as bool?,
      tieneRecetas: tieneRecetas == _absent
          ? this.tieneRecetas
          : tieneRecetas as bool?,
      tieneTratamientos: tieneTratamientos == _absent
          ? this.tieneTratamientos
          : tieneTratamientos as bool?,
      soloEmergencias: soloEmergencias == _absent
          ? this.soloEmergencias
          : soloEmergencias as bool?,
    );
  }

  @override
  List<Object?> get props => [
    todas,
    filtradas,
    doctores,
    pacienteNombres,
    doctorNombres,
    puedeFiltrarPorDoctor,
    busquedaPaciente,
    doctorIdFiltro,
    rangoFechas,
    finalizada,
    tieneNotas,
    tieneOdontograma,
    tieneRecetas,
    tieneTratamientos,
    soloEmergencias,
  ];
}

const _absent = Object();

class ConsultasError extends ConsultasListState {
  final String message;
  const ConsultasError(this.message);

  @override
  List<Object?> get props => [message];
}
