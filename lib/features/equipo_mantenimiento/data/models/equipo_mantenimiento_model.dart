import 'package:salud_dental_clinic_management/features/equipo_mantenimiento/domain/entities/equipo_mantenimiento.dart';

class EquipoMantenimientoModel extends EquipoMantenimiento {
  EquipoMantenimientoModel({
    super.id,
    required super.equipoId,
    super.consumibleId,
    required super.descripcion,
    super.suplidorId,
    required super.costo,
    required super.fechaMantenimiento,
  });

  factory EquipoMantenimientoModel.fromJson(Map<String, dynamic> json) {
    return EquipoMantenimientoModel(
      id: json['id'] as String?,
      equipoId: json['equipo_id'] ?? json['equipoId'],
      consumibleId: json['consumible_id'] ?? json['consumibleId'],
      descripcion: json['descripcion'] as String,
      suplidorId: json['suplidor_id'] ?? json['suplidorId'],
      costo: (json['costo'] as num).toDouble(),
      fechaMantenimiento: DateTime.parse(
        json['fecha_mantenimiento'] ?? json['fechaMantenimiento'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'equipo_id': equipoId,
      'consumible_id': consumibleId,
      'descripcion': descripcion,
      'suplidor_id': suplidorId,
      'costo': costo,
      'fecha_mantenimiento': fechaMantenimiento.toIso8601String(),
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
