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

/// La consulta (con odontograma, dientes y superficies) quedó creada.
class ConsultaCreada extends ConsultaState {
  const ConsultaCreada();
}

/// Falló la operación; no se registró nada (sin huérfanos).
class ConsultaError extends ConsultaState {
  final String message;

  const ConsultaError(this.message);

  @override
  List<Object?> get props => [message];
}
