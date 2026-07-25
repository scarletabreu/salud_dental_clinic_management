import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

class ItemPlanTratamientoModel extends ItemPlanTratamiento {
  const ItemPlanTratamientoModel({
    super.id,
    required super.planId,
    required super.tratamientoId,
    super.diagnosticoAplicadoId,
    super.dienteId,
    super.superficie,
    super.estado,
    super.precioEstimado,
    super.orden,
    super.notas,
    super.doctorProponeId,
    required super.fechaPropuesta,
    super.fechaAceptacion,
    super.fechaRechazo,
    super.motivoRechazo,
    super.fechaInicio,
    super.fechaCompletado,
    super.nombreTratamiento,
  });

  factory ItemPlanTratamientoModel.fromEntity(ItemPlanTratamiento item) {
    return ItemPlanTratamientoModel(
      id: item.id,
      planId: item.planId,
      tratamientoId: item.tratamientoId,
      diagnosticoAplicadoId: item.diagnosticoAplicadoId,
      dienteId: item.dienteId,
      superficie: item.superficie,
      estado: item.estado,
      precioEstimado: item.precioEstimado,
      orden: item.orden,
      notas: item.notas,
      doctorProponeId: item.doctorProponeId,
      fechaPropuesta: item.fechaPropuesta,
      fechaAceptacion: item.fechaAceptacion,
      fechaRechazo: item.fechaRechazo,
      motivoRechazo: item.motivoRechazo,
      fechaInicio: item.fechaInicio,
      fechaCompletado: item.fechaCompletado,
      nombreTratamiento: item.nombreTratamiento,
    );
  }

  factory ItemPlanTratamientoModel.fromJson(Map<String, dynamic> json) {
    final tratamiento = json['tratamiento'];
    return ItemPlanTratamientoModel(
      id: json['id'] as String?,
      planId: json['plan_id'] as String? ?? '',
      tratamientoId: json['tratamiento_id'] as String? ?? '',
      diagnosticoAplicadoId: json['diagnostico_aplicado_id'] as String?,
      dienteId: json['diente_id'] as String?,
      superficie: _parseSuperficie(json['superficie']),
      estado: EstadoItemPlan.fromDb(json['estado'] as String?),
      precioEstimado: (json['precio_estimado'] as num?)?.toDouble() ?? 0,
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      notas: json['notas'] as String?,
      doctorProponeId: json['doctor_propone_id'] as String?,
      fechaPropuesta:
          _parseFecha(json['fecha_propuesta']) ?? DateTime.now().toUtc(),
      fechaAceptacion: _parseFecha(json['fecha_aceptacion']),
      fechaRechazo: _parseFecha(json['fecha_rechazo']),
      motivoRechazo: json['motivo_rechazo'] as String?,
      fechaInicio: _parseFecha(json['fecha_inicio']),
      fechaCompletado: _parseFecha(json['fecha_completado']),
      nombreTratamiento: tratamiento is Map
          ? tratamiento['nombre'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'plan_id': planId,
      'tratamiento_id': tratamientoId,
      'diagnostico_aplicado_id': diagnosticoAplicadoId,
      'diente_id': dienteId,
      'superficie': superficie?.name.toLowerCase(),
      'estado': estado.dbValue,
      'precio_estimado': precioEstimado,
      'orden': orden,
      'notas': notas,
      'doctor_propone_id': doctorProponeId,
      'fecha_propuesta': fechaPropuesta.toUtc().toIso8601String(),
      'fecha_aceptacion': fechaAceptacion?.toUtc().toIso8601String(),
      'fecha_rechazo': fechaRechazo?.toUtc().toIso8601String(),
      'motivo_rechazo': motivoRechazo,
      'fecha_inicio': fechaInicio?.toUtc().toIso8601String(),
      'fecha_completado': fechaCompletado?.toUtc().toIso8601String(),
    };

    if (id != null && id!.length == 36 && id!.contains('-')) {
      data['id'] = id;
    }
    return data;
  }

  static DateTime? _parseFecha(dynamic raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString());

  static TipoSuperficie? _parseSuperficie(dynamic raw) {
    if (raw == null) return null;
    final valor = raw.toString().toLowerCase();
    for (final superficie in TipoSuperficie.values) {
      if (superficie.name.toLowerCase() == valor) return superficie;
    }
    return null;
  }
}
