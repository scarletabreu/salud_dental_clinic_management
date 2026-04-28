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
}
