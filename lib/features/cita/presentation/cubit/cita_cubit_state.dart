import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta_de_cita.dart';

enum CalendarioViewMode { mensual, semanal, diaria }

abstract class CitaCubitState extends Equatable {
  const CitaCubitState();

  @override
  List<Object?> get props => [];
}

class CitaCubitLoading extends CitaCubitState {
  const CitaCubitLoading();
}

class CitaCubitLoaded extends CitaCubitState {
  final List<Cita> citas;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarioViewMode viewMode;

  final bool isSubmitting;
  final String? errorMessage;

  /// Consulta de cada cita que tenga una, indexada por `citaId` (SD-160).
  /// Permite saltar de la agenda a la consulta y saber si sigue abierta.
  final Map<String, ConsultaDeCita> consultasPorCitaId;

  /// El actor tiene la agenda acotada a una lista de doctores y esa lista está
  /// vacía. Distingue «no hay citas» de «no tienes a quién ver todavía», que es
  /// el caso del asistente al que nadie ha asignado un odontólogo.
  final bool sinDoctoresAsignados;

  /// Doctor por el que el usuario está filtrando ahora mismo, o `null` para
  /// «todos los que puedo ver».
  ///
  /// Es distinto del techo de seguridad (`doctorIdsPermitidos`, que decide qué
  /// citas llegan siquiera): esto es una preferencia de vista. Antes no
  /// existía, así que el admin veía la agenda de toda la clínica sin poder
  /// quedarse con la suya (defecto D15).
  final String? doctorIdFiltro;

  /// Doctores presentes en el alcance del usuario, para poblar el selector.
  final List<Cita> _todas;

  const CitaCubitLoaded({
    required this.citas,
    required this.focusedDay,
    required this.selectedDay,
    required this.viewMode,
    this.isSubmitting = false,
    this.errorMessage,
    this.consultasPorCitaId = const {},
    this.sinDoctoresAsignados = false,
    this.doctorIdFiltro,
    List<Cita>? todas,
  }) : _todas = todas ?? citas;

  /// Todas las citas del alcance, sin el filtro de doctor aplicado.
  List<Cita> get citasSinFiltrar => _todas;

  /// Los odontólogos que aparecen en el alcance, ordenados por nombre. Sale de
  /// las propias citas para no pedir el catálogo entero de doctores sólo para
  /// pintar un selector.
  List<({String id, String nombre})> get doctoresDelAlcance {
    final porId = <String, String>{};
    for (final cita in _todas) {
      final id = cita.doctor.id;
      if (id == null) continue;
      porId[id] = 'Dr. ${cita.doctor.nombre} ${cita.doctor.apellido}';
    }
    final lista = porId.entries
        .map((e) => (id: e.key, nombre: e.value))
        .toList();
    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  ConsultaDeCita? consultaDe(Cita cita) =>
      cita.id == null ? null : consultasPorCitaId[cita.id];

  List<Cita> citasForDay(DateTime day) {
    return citas
        .where(
          (c) =>
              c.date.year == day.year &&
              c.date.month == day.month &&
              c.date.day == day.day,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  CitaCubitLoaded copyWith({
    List<Cita>? citas,
    DateTime? focusedDay,
    DateTime? selectedDay,
    CalendarioViewMode? viewMode,
    bool? isSubmitting,
    String? Function()? errorMessage,
    Map<String, ConsultaDeCita>? consultasPorCitaId,
    bool? sinDoctoresAsignados,
    String? Function()? doctorIdFiltro,
    List<Cita>? todas,
  }) {
    return CitaCubitLoaded(
      citas: citas ?? this.citas,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      viewMode: viewMode ?? this.viewMode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      consultasPorCitaId: consultasPorCitaId ?? this.consultasPorCitaId,
      sinDoctoresAsignados:
          sinDoctoresAsignados ?? this.sinDoctoresAsignados,
      doctorIdFiltro: doctorIdFiltro != null
          ? doctorIdFiltro()
          : this.doctorIdFiltro,
      todas: todas ?? _todas,
    );
  }

  @override
  List<Object?> get props => [
    citas,
    focusedDay,
    selectedDay,
    viewMode,
    isSubmitting,
    errorMessage,
    consultasPorCitaId,
    sinDoctoresAsignados,
    doctorIdFiltro,
    _todas,
  ];
}

class CitaCubitError extends CitaCubitState {
  final String message;

  const CitaCubitError(this.message);

  @override
  List<Object?> get props => [message];
}
