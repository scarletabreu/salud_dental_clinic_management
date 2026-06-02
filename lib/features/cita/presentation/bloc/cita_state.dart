part of 'cita_bloc.dart';

abstract class CitaState {}

class CitaInitial extends CitaState {}

class CitaLoading extends CitaState {}

class CitaLoaded extends CitaState {
  final List<Cita> citas;
  CitaLoaded(this.citas);
}

/// Emitido puntualmente cuando una nueva cita se creó con éxito.
/// El bloc vuelve a [CitaLoaded] con la lista actualizada justo después.
class CitaCreated extends CitaState {}

class CitaError extends CitaState {
  final String message;
  CitaError(this.message);
}