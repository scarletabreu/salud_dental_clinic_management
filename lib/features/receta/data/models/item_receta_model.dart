import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';

class ItemRecetaModel extends ItemReceta {
  const ItemRecetaModel({
    super.id,
    super.medicamentoId,
    required super.nombreMedicamento,
    super.principioActivo,
    super.presentacionConcentracion,
    required super.dosis,
    super.viaAdministracion,
    required super.frecuencia,
    required super.duracion,
    super.cantidadIndicada,
    super.indicacionesEspecificas,
    super.dosisCantidad,
    super.dosisUnidad,
    super.frecuenciaHoras,
    super.duracionDias,
    super.cantidadTotal,
    super.justificacionRiesgo,
  });

  static double? _numero(Object? valor) => switch (valor) {
    num n => n.toDouble(),
    String s => double.tryParse(s),
    _ => null,
  };

  factory ItemRecetaModel.fromJson(Map<String, dynamic> json) {
    return ItemRecetaModel(
      id: json['id'] as String?,
      medicamentoId: json['medicamento_id'] as String?,
      nombreMedicamento:
          (json['nombre_medicamento'] ?? json['titulo'] ?? '') as String,
      principioActivo: json['principio_activo'] as String?,
      presentacionConcentracion:
          (json['presentacion_concentracion'] ?? '') as String,
      dosis: (json['dosis'] ?? '') as String,
      viaAdministracion: (json['via_administracion'] ?? 'vía oral') as String,
      frecuencia: (json['frecuencia'] ?? '') as String,
      duracion: (json['duracion'] ?? '') as String,
      cantidadIndicada: (json['cantidad_indicada'] ?? '') as String,
      indicacionesEspecificas:
          (json['indicaciones_especificas'] ?? json['indicaciones']) as String?,
      dosisCantidad: _numero(json['dosis_cantidad']),
      dosisUnidad: (json['dosis_unidad'] ?? '') as String,
      frecuenciaHoras: _numero(json['frecuencia_horas']),
      duracionDias: _numero(json['duracion_dias'])?.round(),
      cantidadTotal: _numero(json['cantidad_total']),
      justificacionRiesgo: json['justificacion_riesgo'] as String?,
    );
  }

  Map<String, dynamic> toJson({String? recetaId}) {
    return {
      if (id != null) 'id': id,
      if (recetaId != null) 'receta_id': recetaId,
      'medicamento_id': medicamentoId,
      'nombre_medicamento': nombreMedicamento,
      if (principioActivo != null) 'principio_activo': principioActivo,
      'presentacion_concentracion': presentacionConcentracion,
      'dosis': dosis,
      'via_administracion': viaAdministracion,
      'frecuencia': frecuencia,
      'duracion': duracion,
      'cantidad_indicada': cantidadIndicada,
      'indicaciones_especificas': indicacionesEspecificas,
      // Renglón estructurado: es lo que valida el servidor al emitir.
      if (dosisCantidad != null) 'dosis_cantidad': dosisCantidad,
      if (dosisUnidad.trim().isNotEmpty) 'dosis_unidad': dosisUnidad,
      if (frecuenciaHoras != null) 'frecuencia_horas': frecuenciaHoras,
      if (duracionDias != null) 'duracion_dias': duracionDias,
      if (cantidadTotal != null) 'cantidad_total': cantidadTotal,
      if (justificacionRiesgo != null && justificacionRiesgo!.trim().isNotEmpty)
        'justificacion_riesgo': justificacionRiesgo!.trim(),
    };
  }

  factory ItemRecetaModel.fromEntity(ItemReceta entity) {
    return ItemRecetaModel(
      id: entity.id,
      medicamentoId: entity.medicamentoId,
      nombreMedicamento: entity.nombreMedicamento,
      principioActivo: entity.principioActivo,
      presentacionConcentracion: entity.presentacionConcentracion,
      dosis: entity.dosis,
      viaAdministracion: entity.viaAdministracion,
      frecuencia: entity.frecuencia,
      duracion: entity.duracion,
      cantidadIndicada: entity.cantidadIndicada,
      indicacionesEspecificas: entity.indicacionesEspecificas,
      dosisCantidad: entity.dosisCantidad,
      dosisUnidad: entity.dosisUnidad,
      frecuenciaHoras: entity.frecuenciaHoras,
      duracionDias: entity.duracionDias,
      cantidadTotal: entity.cantidadTotal,
      justificacionRiesgo: entity.justificacionRiesgo,
    );
  }
}
