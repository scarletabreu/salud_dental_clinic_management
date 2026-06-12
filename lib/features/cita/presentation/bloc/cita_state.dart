part of 'cita_bloc.dart';

abstract class CitaState {}

class CitaInitial extends CitaState {}

class CitaLoading extends CitaState {}

class CitaLoaded extends CitaState {
  final List<Cita> citas;
  CitaLoaded(this.citas);
}

class CitaCreated extends CitaState {}

class CitaError extends CitaState {
  final String message;
  CitaError(this.message);
}
