import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/foundation.dart' show ValueGetter;
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
  /// Todas las consultas cargadas (sin filtrar).
  final List<Consulta> todas;

  /// Consultas tras aplicar los filtros activos.
  final List<Consulta> filtradas;

  /// Mapa pacienteId -> nombre completo, para mostrar y buscar por nombre.
  final Map<String, String> pacienteNombres;

  /// Mapa doctorId -> nombre completo.
  final Map<String, String> doctorNombres;

  /// Doctores disponibles para el filtro de chips.
  final List<Doctor> doctores;

  /// Si el usuario puede filtrar por doctor (admin). Para un doctor el listado
  /// queda restringido a sus propias consultas y no se muestran los chips.
  final bool puedeFiltrarPorDoctor;

  /// `paciente_id`s con tratamientos aplicados vigentes. El esquema solo
  /// vincula `tratamientos_aplicados` al paciente, así que el indicador de la
  /// card es por paciente (no por consulta).
  final Set<String> pacientesConTratamientos;

  /// Filtros activos.
  final String busquedaPaciente;
  final String? doctorIdFiltro;
  final DateTimeRange? rangoFechas;

  const ConsultasLoaded({
    required this.todas,
    required this.filtradas,
    required this.pacienteNombres,
    required this.doctorNombres,
    required this.doctores,
    this.puedeFiltrarPorDoctor = true,
    this.pacientesConTratamientos = const {},
    this.busquedaPaciente = '',
    this.doctorIdFiltro,
    this.rangoFechas,
  });

  bool get hayFiltrosActivos =>
      busquedaPaciente.trim().isNotEmpty ||
      doctorIdFiltro != null ||
      rangoFechas != null;

  String nombrePaciente(String id) => pacienteNombres[id] ?? 'Paciente desconocido';

  String nombreDoctor(String id) => doctorNombres[id] ?? 'Doctor desconocido';

  /// Indica (por paciente) si la consulta corresponde a un paciente con
  /// tratamientos aplicados vigentes.
  bool pacienteTieneTratamientos(String pacienteId) =>
      pacientesConTratamientos.contains(pacienteId);

  /// Para los campos anulables (`doctorIdFiltro`, `rangoFechas`) se usa un
  /// `ValueGetter`: pasar la función permite distinguir "no cambiar" (null)
  /// de "limpiar el filtro" (() => null).
  ConsultasLoaded copyWith({
    List<Consulta>? filtradas,
    String? busquedaPaciente,
    ValueGetter<String?>? doctorIdFiltro,
    ValueGetter<DateTimeRange?>? rangoFechas,
  }) {
    return ConsultasLoaded(
      todas: todas,
      filtradas: filtradas ?? this.filtradas,
      pacienteNombres: pacienteNombres,
      doctorNombres: doctorNombres,
      doctores: doctores,
      puedeFiltrarPorDoctor: puedeFiltrarPorDoctor,
      pacientesConTratamientos: pacientesConTratamientos,
      busquedaPaciente: busquedaPaciente ?? this.busquedaPaciente,
      doctorIdFiltro:
          doctorIdFiltro != null ? doctorIdFiltro() : this.doctorIdFiltro,
      rangoFechas: rangoFechas != null ? rangoFechas() : this.rangoFechas,
    );
  }

  @override
  List<Object?> get props => [
    todas,
    filtradas,
    pacientesConTratamientos,
    busquedaPaciente,
    doctorIdFiltro,
    rangoFechas,
  ];
}

class ConsultasError extends ConsultasListState {
  final String message;

  const ConsultasError(this.message);

  @override
  List<Object?> get props => [message];
}
