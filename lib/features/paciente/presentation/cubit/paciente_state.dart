import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';

abstract class PacienteState extends Equatable {
  const PacienteState();

  @override
  List<Object?> get props => [];
}

class PacienteLoading extends PacienteState {
  const PacienteLoading();
}

class PacienteLoaded extends PacienteState {
  final List<Paciente> todos;
  final List<Paciente> filtrados;

  const PacienteLoaded({required this.todos, required this.filtrados});

  @override
  List<Object?> get props => [todos, filtrados];
}

class PacienteDetailLoading extends PacienteState {
  const PacienteDetailLoading();
}

class PacienteDetailLoaded extends PacienteState {
  final Paciente paciente;

  /// El paciente cargó pero su historial de consultas no. Sin esta distinción
  /// un fallo de red se ve igual que un paciente sin consultas, y el expediente
  /// afirma que no hay odontograma cuando en realidad no pudo leerlo.
  final bool historialNoDisponible;

  /// La línea de tiempo de cada pieza del paciente (SD-144). Vacío cuando aún
  /// no cargó o cuando su lectura falló: el expediente se abre igual y las
  /// fichas de pieza se quedan con lo que dibuja el odontograma.
  final HistorialPiezas historialPiezas;

  const PacienteDetailLoaded(
    this.paciente, {
    this.historialNoDisponible = false,
    this.historialPiezas = HistorialPiezas.vacio,
  });

  @override
  List<Object?> get props => [
    paciente,
    historialNoDisponible,
    historialPiezas.porFdi.length,
  ];
}

class PacienteError extends PacienteState {
  final String message;

  const PacienteError(this.message);

  @override
  List<Object?> get props => [message];
}

class PacienteOperationSuccess extends PacienteState {
  const PacienteOperationSuccess();
}