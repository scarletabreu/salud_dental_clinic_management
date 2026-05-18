import 'package:equatable/equatable.dart';
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

class PacienteError extends PacienteState {
  final String message;

  const PacienteError(this.message);

  @override
  List<Object?> get props => [message];
}
