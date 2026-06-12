import 'package:equatable/equatable.dart';

abstract class ConsultaState extends Equatable {
  const ConsultaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial, antes de intentar guardar.
class ConsultaInitial extends ConsultaState {
  const ConsultaInitial();
}

/// Guardando: subiendo documentos y ejecutando el RPC transaccional.
class ConsultaLoading extends ConsultaState {
  const ConsultaLoading();
}

/// La consulta (con odontograma, dientes y superficies) quedó creada; se pasa
/// al workspace clínico (odontograma, tratamientos, notas).
class ConsultaCreada extends ConsultaState {
  const ConsultaCreada();
}

/// El doctor finalizó la consulta ("Terminar consulta"); si venía de una cita,
/// esta se marcó como completada.
class ConsultaTerminada extends ConsultaState {
  const ConsultaTerminada();
}

/// Falló la operación; no se registró nada (sin huérfanos).
class ConsultaError extends ConsultaState {
  final String message;

  const ConsultaError(this.message);

  @override
  List<Object?> get props => [message];
}
