import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Estado de un procedimiento **ya ejecutado**. Desde SD-135 esta tabla no
/// alberga intenciones: lo que se piensa hacer vive en el plan de tratamiento
/// (`items_plan_tratamiento`), no aquí. Por eso desapareció `indicado`.
///
/// Coincide con el CHECK `tratamientos_aplicados_solo_ejecucion` de Postgres.
enum EstadoTratamientoAplicado {
  /// La ejecución empezó y sigue abierta (un conducto en varias sesiones).
  enProceso,

  /// Se ejecutó. Es el estado normal de un procedimiento de una sola sesión.
  aplicado,

  /// Ejecución cerrada de un procedimiento que venía en varias sesiones.
  completado;

  String get dbValue =>
      this == EstadoTratamientoAplicado.enProceso ? 'en_proceso' : name;

  static EstadoTratamientoAplicado fromDb(String? valor) {
    if (valor == 'en_proceso') return EstadoTratamientoAplicado.enProceso;
    // `indicado` es de antes de SD-135: era una intención guardada en el eje de
    // ejecución. La migración las movió al plan y borró lógicamente sus filas;
    // si alguna sobrevive, se lee como iniciada y no como terminada.
    if (valor == 'indicado') return EstadoTratamientoAplicado.enProceso;
    return EstadoTratamientoAplicado.values.firstWhere(
      (estado) => estado.name == valor,
      orElse: () => EstadoTratamientoAplicado.aplicado,
    );
  }
}

class TratamientoAplicado {
  final String? id;
  final String tratamientoId;
  final String? tratamientoPadreId;
  final bool esContinuo;
  final bool estaTerminado;

  /// Consulta a la que pertenece el tratamiento (facturación por consulta).
  final String? consultaId;

  /// Diente donde se aplicó. `null` = tratamiento general (p. ej. limpieza).
  final String? dienteId;

  /// Superficie concreta del diente, si aplica.
  final TipoSuperficie? superficie;

  /// Precio copiado del catálogo al momento de aplicar (congelado).
  final double? precioAplicado;

  /// Justificación clínica del tratamiento (HOTFIX-5).
  final String? notas;
  final EstadoTratamientoAplicado estado;
  final String? nombreTratamiento;
  final String? claveOdontograma;
  final DateTime? fechaAplicacion;

  /// Actividad del plan que esta ejecución cumple. `null` = ejecución no
  /// planificada (una urgencia resuelta en el momento), que es legítima.
  final String? itemPlanId;

  /// Auditoría de la ejecución: quién la hizo y cuándo (SD-135).
  final String? doctorEjecutaId;
  final DateTime? fechaEjecucion;
  final double cantidadRealizada;

  TratamientoAplicado({
    this.id,
    required this.tratamientoId,
    this.tratamientoPadreId,
    required this.esContinuo,
    required this.estaTerminado,
    this.consultaId,
    this.dienteId,
    this.superficie,
    this.precioAplicado,
    this.notas,
    this.estado = EstadoTratamientoAplicado.aplicado,
    this.nombreTratamiento,
    this.claveOdontograma,
    this.fechaAplicacion,
    this.itemPlanId,
    this.doctorEjecutaId,
    this.fechaEjecucion,
    this.cantidadRealizada = 1,
  });

  TratamientoAplicado copyWith({
    /// Solo se pasa al sellar sobre el estado en memoria el id que devolvió la
    /// BD: una fila ya persistida no cambia de identidad.
    String? id,
    String? tratamientoId,
    String? tratamientoPadreId,
    bool? esContinuo,
    bool? estaTerminado,
    String? consultaId,
    String? dienteId,
    TipoSuperficie? superficie,
    double? precioAplicado,
    String? notas,
    EstadoTratamientoAplicado? estado,
    String? nombreTratamiento,
    String? claveOdontograma,
    DateTime? fechaAplicacion,
    String? itemPlanId,
    String? doctorEjecutaId,
    DateTime? fechaEjecucion,
    double? cantidadRealizada,
  }) {
    return TratamientoAplicado(
      id: id ?? this.id,
      tratamientoId: tratamientoId ?? this.tratamientoId,
      tratamientoPadreId: tratamientoPadreId ?? this.tratamientoPadreId,
      esContinuo: esContinuo ?? this.esContinuo,
      estaTerminado: estaTerminado ?? this.estaTerminado,
      consultaId: consultaId ?? this.consultaId,
      dienteId: dienteId ?? this.dienteId,
      superficie: superficie ?? this.superficie,
      precioAplicado: precioAplicado ?? this.precioAplicado,
      notas: notas ?? this.notas,
      estado: estado ?? this.estado,
      nombreTratamiento: nombreTratamiento ?? this.nombreTratamiento,
      claveOdontograma: claveOdontograma ?? this.claveOdontograma,
      fechaAplicacion: fechaAplicacion ?? this.fechaAplicacion,
      itemPlanId: itemPlanId ?? this.itemPlanId,
      doctorEjecutaId: doctorEjecutaId ?? this.doctorEjecutaId,
      fechaEjecucion: fechaEjecucion ?? this.fechaEjecucion,
      cantidadRealizada: cantidadRealizada ?? this.cantidadRealizada,
    );
  }
}
