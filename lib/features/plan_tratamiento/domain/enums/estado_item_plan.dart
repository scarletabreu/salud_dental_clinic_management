/// Ciclo de vida de una actividad planificada. Los nombres coinciden 1:1 con el
/// enum `estado_item_plan` de Postgres: ver
/// `supabase/migrations/20260725120000_sd_135_evaluacion_plan_ejecucion.sql`.
///
/// Ninguno de estos estados factura. El cargo nace al registrar la ejecución en
/// `tratamientos_aplicados`, nunca aquí (SD-135).
enum EstadoItemPlan {
  /// El doctor la propuso; el paciente todavía no decide.
  propuesto,

  /// El paciente la aceptó. Aún no se agenda ni se ejecuta.
  aceptado,

  /// El paciente la rechazó. Terminal: queda como constancia de que se ofreció.
  rechazado,

  /// Aceptada y esperando turno de ejecución.
  pendiente,

  /// Su ejecución empezó y no ha terminado (un conducto en varias sesiones).
  enProceso,

  /// Ejecutada por completo. Terminal.
  completado,

  /// Se descartó por decisión clínica o administrativa. Terminal.
  cancelado;

  /// Valor tal cual se guarda en la columna `estado` de Postgres.
  String get dbValue => this == EstadoItemPlan.enProceso ? 'en_proceso' : name;

  static EstadoItemPlan fromDb(String? valor) {
    if (valor == 'en_proceso') return EstadoItemPlan.enProceso;
    // Puente con SD-150: una indicación era una actividad aún sin decidir.
    if (valor == 'indicado') return EstadoItemPlan.propuesto;
    return EstadoItemPlan.values.firstWhere(
      (estado) => estado.name == valor,
      orElse: () => EstadoItemPlan.propuesto,
    );
  }

  String get etiqueta {
    switch (this) {
      case EstadoItemPlan.propuesto:
        return 'Propuesta';
      case EstadoItemPlan.aceptado:
        return 'Aceptada';
      case EstadoItemPlan.rechazado:
        return 'Rechazada';
      case EstadoItemPlan.pendiente:
        return 'Pendiente';
      case EstadoItemPlan.enProceso:
        return 'En proceso';
      case EstadoItemPlan.completado:
        return 'Completada';
      case EstadoItemPlan.cancelado:
        return 'Cancelada';
    }
  }

  /// Estados a los que esta actividad puede pasar legalmente.
  /// Los terminales (rechazado, completado, cancelado) devuelven `[]`.
  List<EstadoItemPlan> get transicionesPermitidas {
    switch (this) {
      case EstadoItemPlan.propuesto:
        return const [
          EstadoItemPlan.aceptado,
          EstadoItemPlan.rechazado,
          EstadoItemPlan.cancelado,
        ];
      case EstadoItemPlan.aceptado:
        return const [
          EstadoItemPlan.pendiente,
          EstadoItemPlan.enProceso,
          EstadoItemPlan.cancelado,
        ];
      case EstadoItemPlan.pendiente:
        return const [EstadoItemPlan.enProceso, EstadoItemPlan.cancelado];
      case EstadoItemPlan.enProceso:
        return const [EstadoItemPlan.completado, EstadoItemPlan.cancelado];
      case EstadoItemPlan.rechazado:
      case EstadoItemPlan.completado:
      case EstadoItemPlan.cancelado:
        return const [];
    }
  }

  bool puedeTransicionarA(EstadoItemPlan destino) =>
      transicionesPermitidas.contains(destino);

  bool get esTerminal => transicionesPermitidas.isEmpty;

  /// Una actividad solo admite registro de ejecución cuando ya se decidió
  /// hacerla. Es el mismo contrato que impone el trigger
  /// `trg_item_plan_ejecutable` en la base de datos.
  bool get admiteEjecucion => const {
    EstadoItemPlan.aceptado,
    EstadoItemPlan.pendiente,
    EstadoItemPlan.enProceso,
    EstadoItemPlan.completado,
  }.contains(this);
}
