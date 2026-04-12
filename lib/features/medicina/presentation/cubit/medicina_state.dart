part of 'medicina_cubit.dart';

abstract class MedicinaState extends Equatable {
  const MedicinaState();

  @override
  List<Object> get props => [];
}

class MedicinaInitial extends MedicinaState {
  const MedicinaInitial();
}

class MedicinaLoading extends MedicinaState {
  const MedicinaLoading();
}

class MedicinaLoaded extends MedicinaState {
  final List<Medicina> medicinas;

  const MedicinaLoaded(this.medicinas);

  @override
  List<Object> get props => [medicinas];
}

class MedicinaError extends MedicinaState {
  final String message;

  const MedicinaError(this.message);

  @override
  List<Object> get props => [message];
}
