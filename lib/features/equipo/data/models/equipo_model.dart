import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';

class EquipoModel extends Equipo {
  EquipoModel({
    required super.id,
    required super.nombre,
    required super.descripcion,
    required super.ultimoMantenimiento,
    required super.tiempoParaMantenimiento,
  });

  factory EquipoModel.fromJson(Map<String, dynamic> json) {
    return EquipoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] ?? '',
      ultimoMantenimiento: DateTime.parse(
        json['ultimo_mantenimiento'] ?? json['ultimoMantenimiento'],
      ),
      tiempoParaMantenimiento:
          (json['tiempo_para_mantenimiento'] ??
                  json['tiempoParaMantenimiento'] as num)
              .toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'ultimo_mantenimiento': ultimoMantenimiento.toIso8601String(),
      'tiempo_para_mantenimiento': tiempoParaMantenimiento,
    };
  }
}
