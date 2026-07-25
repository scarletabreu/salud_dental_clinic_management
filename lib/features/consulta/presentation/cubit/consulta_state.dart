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

/// En qué punto está el autoguardado del trabajo clínico. Se muestra en la
/// pantalla: el doctor tiene que poder saber, sin preguntar, si lo que acaba
/// de anotar ya está a salvo.
enum EstadoGuardado {
  /// No hay nada sin guardar.
  alDia,

  /// Hay cambios en memoria esperando al autoguardado.
  pendiente,

  /// Escribiendo en el servidor.
  guardando,

  /// El último intento falló; los cambios siguen en memoria.
  fallido,
}

/// La consulta está activa en memoria. Contiene el odontograma, recetas, notas y signos vitales.
class ConsultaIniciada extends ConsultaState {
  final Consulta consulta;

  /// Estado del autoguardado de [consulta].
  final EstadoGuardado guardado;

  const ConsultaIniciada({
    required this.consulta,
    this.guardado = EstadoGuardado.alDia,
  });

  ConsultaIniciada copyWith({Consulta? consulta, EstadoGuardado? guardado}) =>
      ConsultaIniciada(
        consulta: consulta ?? this.consulta,
        guardado: guardado ?? this.guardado,
      );

  @override
  List<Object?> get props => [consulta, guardado];
}

/// Guardando la consulta (parcial o finalización).
class ConsultaGuardando extends ConsultaState {
  final Consulta? consulta;

  const ConsultaGuardando({this.consulta});

  @override
  List<Object?> get props => [consulta];
}

/// La consulta se finalizó con éxito. Lleva el id de la cuenta (pre-factura)
/// generada, para poder navegar hacia el detalle financiero.
class ConsultaTerminada extends ConsultaState {
  final String? cuentaId;

  const ConsultaTerminada({this.cuentaId});

  @override
  List<Object?> get props => [cuentaId];
}

/// Falló la operación u ocurrió un error.
class ConsultaError extends ConsultaState {
  final String message;

  const ConsultaError(this.message);

  @override
  List<Object?> get props => [message];
}
