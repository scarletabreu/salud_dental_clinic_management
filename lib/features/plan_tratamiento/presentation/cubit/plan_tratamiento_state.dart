import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';

sealed class PlanTratamientoState {
  const PlanTratamientoState();
}

class PlanTratamientoInitial extends PlanTratamientoState {
  const PlanTratamientoInitial();
}

class PlanTratamientoCargando extends PlanTratamientoState {
  const PlanTratamientoCargando();
}

/// El plan de la consulta. `plan == null` significa que todavía no se propuso
/// ninguna actividad: la evaluación puede tener hallazgos y el plan estar vacío,
/// que es exactamente la separación que persigue SD-135.
class PlanTratamientoCargado extends PlanTratamientoState {
  final PlanTratamiento? plan;

  /// Se está guardando un cambio; la interfaz sigue mostrando el plan actual.
  final bool guardando;

  /// Aviso de una transición rechazada por el dominio. No es un fallo técnico:
  /// se muestra y se limpia sin perder el plan en pantalla.
  final String? aviso;

  const PlanTratamientoCargado({
    this.plan,
    this.guardando = false,
    this.aviso,
  });

  PlanTratamientoCargado copyWith({
    PlanTratamiento? plan,
    bool? guardando,
    String? aviso,
    bool limpiarAviso = false,
  }) {
    return PlanTratamientoCargado(
      plan: plan ?? this.plan,
      guardando: guardando ?? this.guardando,
      aviso: limpiarAviso ? null : (aviso ?? this.aviso),
    );
  }
}

class PlanTratamientoError extends PlanTratamientoState {
  final String mensaje;
  const PlanTratamientoError(this.mensaje);
}
