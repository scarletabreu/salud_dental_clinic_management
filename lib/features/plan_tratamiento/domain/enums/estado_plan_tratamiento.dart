/// Ciclo de vida del plan completo. Coincide 1:1 con el enum
/// `estado_plan_tratamiento` de Postgres.
///
/// Es el mismo vocabulario que `EstadoItemPlan` salvo `pendiente`, que solo
/// tiene sentido por actividad, y `borrador`, que solo tiene sentido por plan:
/// el doctor lo arma antes de presentarlo al paciente.
enum EstadoPlanTratamiento {
  borrador,
  propuesto,
  aceptado,
  rechazado,
  enProceso,
  completado,
  cancelado;

  String get dbValue =>
      this == EstadoPlanTratamiento.enProceso ? 'en_proceso' : name;

  static EstadoPlanTratamiento fromDb(String? valor) {
    if (valor == 'en_proceso') return EstadoPlanTratamiento.enProceso;
    return EstadoPlanTratamiento.values.firstWhere(
      (estado) => estado.name == valor,
      orElse: () => EstadoPlanTratamiento.borrador,
    );
  }

  String get etiqueta {
    switch (this) {
      case EstadoPlanTratamiento.borrador:
        return 'Borrador';
      case EstadoPlanTratamiento.propuesto:
        return 'Propuesto';
      case EstadoPlanTratamiento.aceptado:
        return 'Aceptado';
      case EstadoPlanTratamiento.rechazado:
        return 'Rechazado';
      case EstadoPlanTratamiento.enProceso:
        return 'En proceso';
      case EstadoPlanTratamiento.completado:
        return 'Completado';
      case EstadoPlanTratamiento.cancelado:
        return 'Cancelado';
    }
  }

  List<EstadoPlanTratamiento> get transicionesPermitidas {
    switch (this) {
      case EstadoPlanTratamiento.borrador:
        return const [
          EstadoPlanTratamiento.propuesto,
          EstadoPlanTratamiento.cancelado,
        ];
      case EstadoPlanTratamiento.propuesto:
        return const [
          EstadoPlanTratamiento.aceptado,
          EstadoPlanTratamiento.rechazado,
          EstadoPlanTratamiento.cancelado,
        ];
      case EstadoPlanTratamiento.aceptado:
        return const [
          EstadoPlanTratamiento.enProceso,
          EstadoPlanTratamiento.cancelado,
        ];
      case EstadoPlanTratamiento.enProceso:
        return const [
          EstadoPlanTratamiento.completado,
          EstadoPlanTratamiento.cancelado,
        ];
      case EstadoPlanTratamiento.rechazado:
      case EstadoPlanTratamiento.completado:
      case EstadoPlanTratamiento.cancelado:
        return const [];
    }
  }

  bool puedeTransicionarA(EstadoPlanTratamiento destino) =>
      transicionesPermitidas.contains(destino);

  bool get esTerminal => transicionesPermitidas.isEmpty;
}
