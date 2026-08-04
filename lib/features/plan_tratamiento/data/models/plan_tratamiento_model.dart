import 'package:salud_dental_clinic_management/features/plan_tratamiento/data/models/item_plan_tratamiento_model.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';

class PlanTratamientoModel extends PlanTratamiento {
  const PlanTratamientoModel({
    super.id,
    required super.pacienteId,
    super.evaluacionId,
    super.consultaOrigenId,
    required super.doctorId,
    super.estado,
    super.version,
    super.notas,
    required super.fechaPropuesta,
    super.fechaAceptacion,
    super.fechaRechazo,
    super.motivoRechazo,
    super.items,
  });

  factory PlanTratamientoModel.fromEntity(PlanTratamiento plan) {
    return PlanTratamientoModel(
      id: plan.id,
      pacienteId: plan.pacienteId,
      evaluacionId: plan.evaluacionId,
      consultaOrigenId: plan.consultaOrigenId,
      doctorId: plan.doctorId,
      estado: plan.estado,
      version: plan.version,
      notas: plan.notas,
      fechaPropuesta: plan.fechaPropuesta,
      fechaAceptacion: plan.fechaAceptacion,
      fechaRechazo: plan.fechaRechazo,
      motivoRechazo: plan.motivoRechazo,
      items: plan.items,
    );
  }

  factory PlanTratamientoModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?) ?? const [];
    return PlanTratamientoModel(
      id: json['id'] as String?,
      pacienteId: json['paciente_id'] as String? ?? '',
      evaluacionId: json['evaluacion_id'] as String?,
      consultaOrigenId: json['consulta_origen_id'] as String?,
      doctorId: json['doctor_id'] as String? ?? '',
      estado: EstadoPlanTratamiento.fromDb(json['estado'] as String?),
      version: (json['version'] as num?)?.toInt() ?? 1,
      notas: json['notas'] as String?,
      fechaPropuesta:
          DateTime.tryParse('${json['fecha_propuesta']}') ??
          DateTime.now().toUtc(),
      fechaAceptacion: json['fecha_aceptacion'] == null
          ? null
          : DateTime.tryParse('${json['fecha_aceptacion']}'),
      fechaRechazo: json['fecha_rechazo'] == null
          ? null
          : DateTime.tryParse('${json['fecha_rechazo']}'),
      motivoRechazo: json['motivo_rechazo'] as String?,
      items: [
        for (final item in items)
          ItemPlanTratamientoModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
      ]..sort((a, b) => a.orden.compareTo(b.orden)),
    );
  }

  /// Solo el encabezado: los items viajan en su propia tabla.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'paciente_id': pacienteId,
      'evaluacion_id': evaluacionId,
      'consulta_origen_id': consultaOrigenId,
      'doctor_id': doctorId,
      'estado': estado.dbValue,
      'notas': notas,
      'fecha_propuesta': fechaPropuesta.toUtc().toIso8601String(),
      'fecha_aceptacion': fechaAceptacion?.toUtc().toIso8601String(),
      'fecha_rechazo': fechaRechazo?.toUtc().toIso8601String(),
      'motivo_rechazo': motivoRechazo,
    };

    if (id != null && id!.length == 36 && id!.contains('-')) {
      data['id'] = id;
    }
    return data;
  }
}
