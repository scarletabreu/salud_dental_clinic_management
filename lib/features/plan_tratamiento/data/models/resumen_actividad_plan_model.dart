import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/resumen_actividad_plan.dart';

class ResumenActividadPlanModel extends ResumenActividadPlan {
  const ResumenActividadPlanModel({
    required super.itemPlanId,
    required super.planId,
    super.pacienteId,
    required super.tratamientoId,
    required super.tratamientoNombre,
    required super.tipoEjecucion,
    super.sesionesPlanificadas,
    required super.estado,
    required super.montoPresupuestado,
    required super.cantidadRealizada,
    required super.montoRealizado,
    required super.montoFacturado,
    required super.montoPagado,
    required super.montoPendiente,
  });

  factory ResumenActividadPlanModel.fromJson(Map<String, dynamic> json) {
    return ResumenActividadPlanModel(
      itemPlanId: json['item_plan_id'] as String,
      planId: json['plan_id'] as String,
      pacienteId: json['paciente_id'] as String?,
      tratamientoId: json['tratamiento_id'] as String,
      tratamientoNombre: json['tratamiento_nombre'] as String? ?? 'Tratamiento',
      tipoEjecucion: (json['tipo_ejecucion'] as String?) == 'por_sesiones'
          ? TipoEjecucionItemPlan.porSesiones
          : TipoEjecucionItemPlan.unica,
      sesionesPlanificadas: (json['sesiones_planificadas'] as num?)?.toInt(),
      estado: json['estado'] as String,
      montoPresupuestado: (json['monto_presupuestado'] as num).toDouble(),
      cantidadRealizada: (json['cantidad_realizada'] as num).toDouble(),
      montoRealizado: (json['monto_realizado'] as num).toDouble(),
      montoFacturado: (json['monto_facturado'] as num).toDouble(),
      montoPagado: (json['monto_pagado'] as num).toDouble(),
      montoPendiente: (json['monto_pendiente'] as num).toDouble(),
    );
  }
}