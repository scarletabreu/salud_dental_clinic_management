import 'package:salud_dental_clinic_management/features/cita/domain/entities/actividad_planificada.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Mapea las vistas `resumen_actividades_cita` y
/// `actividades_agendables_paciente`, que comparten columnas de resumen.
class ActividadPlanificadaModel extends ActividadPlanificada {
  const ActividadPlanificadaModel({
    required super.itemPlanId,
    super.planId,
    super.tratamientoId,
    super.nombreTratamiento,
    super.fdiDiente,
    super.superficie,
    super.estado,
    super.precioEstimado,
    super.orden,
  });

  factory ActividadPlanificadaModel.fromEntity(ActividadPlanificada a) =>
      ActividadPlanificadaModel(
        itemPlanId: a.itemPlanId,
        planId: a.planId,
        tratamientoId: a.tratamientoId,
        nombreTratamiento: a.nombreTratamiento,
        fdiDiente: a.fdiDiente,
        superficie: a.superficie,
        estado: a.estado,
        precioEstimado: a.precioEstimado,
        orden: a.orden,
      );

  factory ActividadPlanificadaModel.fromJson(Map<String, dynamic> json) {
    return ActividadPlanificadaModel(
      itemPlanId: json['item_plan_id'] as String,
      planId: json['plan_id'] as String?,
      tratamientoId: json['tratamiento_id'] as String?,
      nombreTratamiento: json['tratamiento_nombre'] as String?,
      fdiDiente: (json['fdi_diente'] as num?)?.toInt(),
      superficie: _parseSuperficie(json['superficie']),
      estado: EstadoItemPlan.fromDb(json['estado'] as String?),
      precioEstimado: (json['precio_estimado'] as num?)?.toDouble() ?? 0,
      orden: (json['orden'] as num?)?.toInt() ?? 0,
    );
  }

  static TipoSuperficie? _parseSuperficie(dynamic raw) {
    if (raw == null) return null;
    final valor = raw.toString().toLowerCase();
    for (final superficie in TipoSuperficie.values) {
      // `name` está sobrescrito con la etiqueta en español; el valor de la
      // columna es el nombre del enum de Postgres en minúsculas.
      if (superficie.name.toLowerCase() == valor) return superficie;
    }
    return null;
  }
}
