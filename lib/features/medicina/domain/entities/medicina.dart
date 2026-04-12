import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/enums/efecto_secundario.dart';

class Medicina {
  final String id;
  final String nombre;
  final List<Contraindicacion> contraindicaciones;
  final List<EfectoSecundario> efectosSecundarios;

  Medicina({
    required this.id,
    required this.nombre,
    required this.contraindicaciones,
    this.efectosSecundarios = const [],
  });

  Medicina copyWith({
    String? nombre,
    List<Contraindicacion>? contraindicaciones,
    List<EfectoSecundario>? efectosSecundarios,
  }) {
    return Medicina(
      id: id,
      nombre: nombre ?? this.nombre,
      contraindicaciones:
          contraindicaciones ?? List.from(this.contraindicaciones),
      efectosSecundarios:
          efectosSecundarios ?? List.from(this.efectosSecundarios),
    );
  }
}
