import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';

/// Lo que se decide tratar a partir de una evaluación (SD-135).
///
/// Un plan agrupa las actividades propuestas al paciente. Solo entran aquí los
/// hallazgos que el doctor decide tratar: la evaluación puede registrar veinte y
/// el plan incluir tres.
class PlanTratamiento {
  final String? id;
  final String pacienteId;

  /// Evaluación de la que nace. `null` en un plan armado sin evaluación previa
  /// registrada en el sistema.
  final String? evaluacionId;
  final String? consultaOrigenId;

  /// Profesional responsable del plan.
  final String doctorId;
  final EstadoPlanTratamiento estado;
  final String? notas;

  final DateTime fechaPropuesta;
  final DateTime? fechaAceptacion;
  final DateTime? fechaRechazo;
  final String? motivoRechazo;

  final List<ItemPlanTratamiento> items;

  const PlanTratamiento({
    this.id,
    required this.pacienteId,
    this.evaluacionId,
    this.consultaOrigenId,
    required this.doctorId,
    this.estado = EstadoPlanTratamiento.borrador,
    this.notas,
    required this.fechaPropuesta,
    this.fechaAceptacion,
    this.fechaRechazo,
    this.motivoRechazo,
    this.items = const [],
  });

  /// Lo que el paciente vería como presupuesto del plan. No es un cargo: nada
  /// se factura hasta que la actividad se ejecuta.
  double get totalEstimado => items
      .where((item) => item.estado != EstadoItemPlan.rechazado)
      .where((item) => item.estado != EstadoItemPlan.cancelado)
      .fold(0, (suma, item) => suma + item.precioEstimado);

  double get totalAceptado => items
      .where((item) => item.estado.admiteEjecucion)
      .fold(0, (suma, item) => suma + item.precioEstimado);

  List<ItemPlanTratamiento> get pendientesDeDecision =>
      items.where((item) => item.estado == EstadoItemPlan.propuesto).toList();

  PlanTratamiento? transicionarA(
    EstadoPlanTratamiento destino, {
    DateTime? momento,
    String? motivoRechazo,
  }) {
    if (!estado.puedeTransicionarA(destino)) return null;
    final ahora = momento ?? DateTime.now();

    return copyWith(
      estado: destino,
      fechaAceptacion: destino == EstadoPlanTratamiento.aceptado
          ? ahora
          : fechaAceptacion,
      fechaRechazo: destino == EstadoPlanTratamiento.rechazado
          ? ahora
          : fechaRechazo,
      motivoRechazo: destino == EstadoPlanTratamiento.rechazado
          ? motivoRechazo
          : this.motivoRechazo,
    );
  }

  PlanTratamiento copyWith({
    String? id,
    String? pacienteId,
    String? evaluacionId,
    String? consultaOrigenId,
    String? doctorId,
    EstadoPlanTratamiento? estado,
    String? notas,
    DateTime? fechaPropuesta,
    DateTime? fechaAceptacion,
    DateTime? fechaRechazo,
    String? motivoRechazo,
    List<ItemPlanTratamiento>? items,
  }) {
    return PlanTratamiento(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      evaluacionId: evaluacionId ?? this.evaluacionId,
      consultaOrigenId: consultaOrigenId ?? this.consultaOrigenId,
      doctorId: doctorId ?? this.doctorId,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      fechaPropuesta: fechaPropuesta ?? this.fechaPropuesta,
      fechaAceptacion: fechaAceptacion ?? this.fechaAceptacion,
      fechaRechazo: fechaRechazo ?? this.fechaRechazo,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      items: items ?? this.items,
    );
  }
}
