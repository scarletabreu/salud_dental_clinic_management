import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/resumen_actividad_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Una actividad que se decidió tratar: qué procedimiento, sobre qué pieza y
/// cara, por qué hallazgo, y en qué punto está la decisión.
///
/// No es un cargo. [precioEstimado] es la referencia que se le da al paciente al
/// proponer; el importe que se factura sale del `precio_aplicado` congelado al
/// registrar la ejecución.
class ItemPlanTratamiento {
  final String? id;
  final String planId;
  final String tratamientoId;

  /// Hallazgo de la evaluación que justifica la actividad. `null` para lo que no
  /// nace de un hallazgo (una profilaxis, un blanqueamiento).
  final String? diagnosticoAplicadoId;

  final String? dienteId;
  final TipoSuperficie? superficie;
  final EstadoItemPlan estado;
  final double precioEstimado;
  final int orden;
  final String? notas;

  // Auditoría: quién propuso y cuándo ocurrió cada decisión.
  final String? doctorProponeId;
  final DateTime fechaPropuesta;
  final DateTime? fechaAceptacion;
  final DateTime? fechaRechazo;
  final String? motivoRechazo;
  final DateTime? fechaInicio;
  final DateTime? fechaCompletado;

  /// Nombre del catálogo incluido por el JOIN, para no volver a consultarlo al
  /// pintar la lista.
  final String? nombreTratamiento;

  final TipoEjecucionItemPlan tipoEjecucion;
  final int? sesionesPlanificadas;

  const ItemPlanTratamiento({
    this.id,
    required this.planId,
    required this.tratamientoId,
    this.diagnosticoAplicadoId,
    this.dienteId,
    this.superficie,
    this.estado = EstadoItemPlan.propuesto,
    this.precioEstimado = 0,
    this.orden = 0,
    this.notas,
    this.doctorProponeId,
    required this.fechaPropuesta,
    this.fechaAceptacion,
    this.fechaRechazo,
    this.motivoRechazo,
    this.fechaInicio,
    this.fechaCompletado,
    this.nombreTratamiento,
    this.tipoEjecucion = TipoEjecucionItemPlan.unica,
    this.sesionesPlanificadas,
  });

  /// Aplica una transición y sella su fecha. Devuelve `null` si el paso no es
  /// legal según el grafo de [EstadoItemPlan], para que quien llama distinga el
  /// rechazo de un cambio válido en lugar de guardar un estado imposible.
  ItemPlanTratamiento? transicionarA(
    EstadoItemPlan destino, {
    DateTime? momento,
    String? motivoRechazo,
  }) {
    if (!estado.puedeTransicionarA(destino)) return null;
    final ahora = momento ?? DateTime.now();

    return copyWith(
      estado: destino,
      fechaAceptacion: destino == EstadoItemPlan.aceptado
          ? ahora
          : fechaAceptacion,
      fechaRechazo: destino == EstadoItemPlan.rechazado ? ahora : fechaRechazo,
      motivoRechazo: destino == EstadoItemPlan.rechazado
          ? motivoRechazo
          : this.motivoRechazo,
      fechaInicio: destino == EstadoItemPlan.enProceso ? ahora : fechaInicio,
      fechaCompletado: destino == EstadoItemPlan.completado
          ? ahora
          : fechaCompletado,
    );
  }

  ItemPlanTratamiento copyWith({
    String? id,
    String? planId,
    String? tratamientoId,
    String? diagnosticoAplicadoId,
    String? dienteId,
    TipoSuperficie? superficie,
    EstadoItemPlan? estado,
    double? precioEstimado,
    int? orden,
    String? notas,
    String? doctorProponeId,
    DateTime? fechaPropuesta,
    DateTime? fechaAceptacion,
    DateTime? fechaRechazo,
    String? motivoRechazo,
    DateTime? fechaInicio,
    DateTime? fechaCompletado,
    String? nombreTratamiento,
    final TipoEjecucionItemPlan? tipoEjecucion,
    final int? sesionesPlanificadas,
  }) {
    return ItemPlanTratamiento(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      tratamientoId: tratamientoId ?? this.tratamientoId,
      diagnosticoAplicadoId:
          diagnosticoAplicadoId ?? this.diagnosticoAplicadoId,
      dienteId: dienteId ?? this.dienteId,
      superficie: superficie ?? this.superficie,
      estado: estado ?? this.estado,
      precioEstimado: precioEstimado ?? this.precioEstimado,
      orden: orden ?? this.orden,
      notas: notas ?? this.notas,
      doctorProponeId: doctorProponeId ?? this.doctorProponeId,
      fechaPropuesta: fechaPropuesta ?? this.fechaPropuesta,
      fechaAceptacion: fechaAceptacion ?? this.fechaAceptacion,
      fechaRechazo: fechaRechazo ?? this.fechaRechazo,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaCompletado: fechaCompletado ?? this.fechaCompletado,
      nombreTratamiento: nombreTratamiento ?? this.nombreTratamiento,
      tipoEjecucion: tipoEjecucion ?? this.tipoEjecucion,
      sesionesPlanificadas: sesionesPlanificadas ?? this.sesionesPlanificadas,
    );
  }
}
