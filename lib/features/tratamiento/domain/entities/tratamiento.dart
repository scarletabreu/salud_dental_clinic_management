import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';

class Tratamiento {
  final String id;
  final String nombre;
  final String descripcion;
  final double costo;
  final List<Contraindicacion> contraindicaciones;
  final Alcance alcance;

  Tratamiento({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.costo,
    required this.contraindicaciones,
    required this.alcance,
  });

  Tratamiento copyWith({
    String? nombre,
    String? descripcion,
    double? costo,
    List<Contraindicacion>? contraindicaciones,
    Alcance? alcance,
  }) {
    return Tratamiento(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      costo: costo ?? this.costo,
      contraindicaciones: contraindicaciones ?? this.contraindicaciones,
      alcance: alcance ?? this.alcance,
    );
  }

  factory Tratamiento.fromJson(Map<String, dynamic> json) {
  return Tratamiento(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String,
    costo: (json['costo'] as num).toDouble(),

    contraindicaciones: (json['contraindicaciones'] as List<dynamic>? ?? [])
        .map((e) => Contraindicacion.fromJson(e as Map<String, dynamic>))
        .toList(),

    alcance: Alcance.values.byName(json['alcance'] as String),
  );
}
}
