import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/enums/efecto_secundario.dart';

class Medicina {
  final String? id;
  final String nombre;

  /// Principio activo del catálogo. `null` significa que no lo sabemos, y por
  /// eso la receta informa "información insuficiente" en vez de afirmar que no
  /// hay conflicto (HFX-CLIN-003).
  final String? principioActivo;
  final List<Contraindicacion> contraindicaciones;
  final List<EfectoSecundario> efectosSecundarios;

  Medicina({
    this.id,
    required this.nombre,
    this.principioActivo,
    required this.contraindicaciones,
    this.efectosSecundarios = const [],
  });

  Medicina copyWith({
    String? nombre,
    String? principioActivo,
    List<Contraindicacion>? contraindicaciones,
    List<EfectoSecundario>? efectosSecundarios,
  }) {
    return Medicina(
      id: id,
      nombre: nombre ?? this.nombre,
      principioActivo: principioActivo ?? this.principioActivo,
      contraindicaciones:
          contraindicaciones ?? List.from(this.contraindicaciones),
      efectosSecundarios:
          efectosSecundarios ?? List.from(this.efectosSecundarios),
    );
  }
}
