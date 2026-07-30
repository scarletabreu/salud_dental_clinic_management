import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Actividad del plan de tratamiento que una cita se propone atender (SD-146).
///
/// Es una vista reducida de `items_plan_tratamiento`: solo el procedimiento, la
/// pieza, la cara y en qué punto está la decisión. No trae el diagnóstico que la
/// originó ni las notas clínicas, porque quien agenda es el asistente y la
/// agenda no es el expediente — la base lo impone sirviéndola por las vistas
/// `resumen_actividades_cita` y `actividades_agendables_paciente`.
///
/// La cita apunta a la actividad; nunca la copia. Cambiar el plan cambia lo que
/// la agenda muestra, sin arrastrar una descripción congelada.
class ActividadPlanificada {
  final String itemPlanId;
  final String? planId;
  final String? tratamientoId;

  /// Nombre del catálogo (`tratamientos.nombre`). `null` si el tratamiento fue
  /// retirado del catálogo después de planificarse.
  final String? nombreTratamiento;

  final int? fdiDiente;
  final TipoSuperficie? superficie;
  final EstadoItemPlan estado;

  /// Referencia que se le dio al paciente al proponer. No es un cargo (SD-135).
  final double precioEstimado;

  final int orden;

  const ActividadPlanificada({
    required this.itemPlanId,
    this.planId,
    this.tratamientoId,
    this.nombreTratamiento,
    this.fdiDiente,
    this.superficie,
    this.estado = EstadoItemPlan.propuesto,
    this.precioEstimado = 0,
    this.orden = 0,
  });

  /// Una línea legible: «Resina compuesta · Pieza 16 · Oclusal».
  String get descripcion {
    final partes = <String>[
      nombreTratamiento?.trim().isNotEmpty == true
          ? nombreTratamiento!.trim()
          : 'Procedimiento sin nombre',
      if (fdiDiente != null) 'Pieza $fdiDiente',
      if (superficie != null) superficie!.name,
    ];
    return partes.join(' · ');
  }

  @override
  bool operator ==(Object other) =>
      other is ActividadPlanificada && other.itemPlanId == itemPlanId;

  @override
  int get hashCode => itemPlanId.hashCode;
}
