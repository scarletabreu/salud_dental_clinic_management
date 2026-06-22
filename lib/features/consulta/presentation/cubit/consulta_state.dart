import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';

sealed class ConsultaState extends Equatable {
  const ConsultaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial, antes de iniciar o cargar la consulta clínica.
class ConsultaInactiva extends ConsultaState {
  const ConsultaInactiva();
}

/// La consulta está activa en memoria. Contiene el odontograma, recetas, notas y signos vitales.
class ConsultaIniciada extends ConsultaState {
  final Consulta consulta;

  const ConsultaIniciada({
    required this.consulta,
  });

  @override
  List<Object?> get props => [consulta];
}

/// Guardando la consulta (parcial o finalización).
class ConsultaGuardando extends ConsultaState {
  final Consulta? consulta;

  const ConsultaGuardando({this.consulta});

  @override
  List<Object?> get props => [consulta];
}

/// La consulta se finalizó con éxito.
class ConsultaTerminada extends ConsultaState {
  const ConsultaTerminada();
}

/// Falló la operación u ocurrió un error.
class ConsultaError extends ConsultaState {
  final String message;

  const ConsultaError(this.message);

  @override
  List<Object?> get props => [message];
}
