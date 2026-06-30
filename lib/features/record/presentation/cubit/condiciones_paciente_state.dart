import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';

abstract class CondicionesPacienteState extends Equatable {
  const CondicionesPacienteState();

  @override
  List<Object?> get props => [];
}

class CondicionesPacienteLoading extends CondicionesPacienteState {
  const CondicionesPacienteLoading();
}

class CondicionesPacienteLoaded extends CondicionesPacienteState {
  final List<Condicion> condiciones;

  /// `true` mientras se agrega o quita una condición (para deshabilitar la UI).
  final bool procesando;

  const CondicionesPacienteLoaded(
    this.condiciones, {
    this.procesando = false,
  });

  CondicionesPacienteLoaded copyWith({
    List<Condicion>? condiciones,
    bool? procesando,
  }) {
    return CondicionesPacienteLoaded(
      condiciones ?? this.condiciones,
      procesando: procesando ?? this.procesando,
    );
  }

  @override
  List<Object?> get props => [condiciones, procesando];
}

class CondicionesPacienteError extends CondicionesPacienteState {
  final String message;

  const CondicionesPacienteError(this.message);

  @override
  List<Object?> get props => [message];
}
