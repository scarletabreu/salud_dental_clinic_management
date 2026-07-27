import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';

class ItemRecetaModel extends ItemReceta {
  const ItemRecetaModel({
    super.id,
    super.medicamentoId,
    required super.nombreMedicamento,
    super.presentacionConcentracion,
    required super.dosis,
    super.viaAdministracion,
    required super.frecuencia,
    required super.duracion,
    super.cantidadIndicada,
    super.indicacionesEspecificas,
  });

  factory ItemRecetaModel.fromJson(Map<String, dynamic> json) {
    return ItemRecetaModel(
      id: json['id'] as String?,
      medicamentoId: json['medicamento_id'] as String?,
      nombreMedicamento:
          (json['nombre_medicamento'] ?? json['titulo'] ?? '') as String,
      presentacionConcentracion:
          (json['presentacion_concentracion'] ?? '') as String,
      dosis: (json['dosis'] ?? '') as String,
      viaAdministracion: (json['via_administracion'] ?? 'vía oral') as String,
      frecuencia: (json['frecuencia'] ?? '') as String,
      duracion: (json['duracion'] ?? '') as String,
      cantidadIndicada: (json['cantidad_indicada'] ?? '') as String,
      indicacionesEspecificas:
          (json['indicaciones_especificas'] ?? json['indicaciones']) as String?,
    );
  }

  Map<String, dynamic> toJson({required String recetaId}) {
    return {
      if (id != null) 'id': id,
      'receta_id': recetaId,
      'medicamento_id': medicamentoId,
      'nombre_medicamento': nombreMedicamento,
      'presentacion_concentracion': presentacionConcentracion,
      'dosis': dosis,
      'via_administracion': viaAdministracion,
      'frecuencia': frecuencia,
      'duracion': duracion,
      'cantidad_indicada': cantidadIndicada,
      'indicaciones_especificas': indicacionesEspecificas,
    };
  }

  factory ItemRecetaModel.fromEntity(ItemReceta entity) {
    return ItemRecetaModel(
      id: entity.id,
      medicamentoId: entity.medicamentoId,
      nombreMedicamento: entity.nombreMedicamento,
      presentacionConcentracion: entity.presentacionConcentracion,
      dosis: entity.dosis,
      viaAdministracion: entity.viaAdministracion,
      frecuencia: entity.frecuencia,
      duracion: entity.duracion,
      cantidadIndicada: entity.cantidadIndicada,
      indicacionesEspecificas: entity.indicacionesEspecificas,
    );
  }
}
