import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';

class Procedimiento {
  final String? id;
  final String nombre;
  final List<Contraindicacion> contraindicaciones;

  Procedimiento({
    this.id,
    required this.nombre,
    required this.contraindicaciones,
  });

  Procedimiento copyWith({
    String? nombre,
    List<Contraindicacion>? contraindicaciones,
  }) {
    return Procedimiento(
      id: id,
      nombre: nombre ?? this.nombre,
      contraindicaciones: contraindicaciones ?? this.contraindicaciones,
    );
  }
}
