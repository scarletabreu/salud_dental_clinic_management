part of 'cita_bloc.dart';

abstract class CitaEvent {}

class LoadCitasEvent extends CitaEvent {}

class CreateCitaEvent extends CitaEvent {
  final Cita cita;
  CreateCitaEvent(this.cita);
}

class DeleteCitaEvent extends CitaEvent {
  final String id;
  DeleteCitaEvent(this.id);
}