import 'package:salud_dental_clinic_management/features/condicion/domain/enums/categoria_condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/tipo_condicion.dart';

class Condicion {
  final String id;
  final String nombre;
  final TipoCondicion tipo;
  final CategoriaCondicion categoria;

  Condicion({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.categoria,
  });

  Condicion copyWith({
    String? nombre,
    TipoCondicion? tipo,
    CategoriaCondicion? categoria,
  }) {
    return Condicion(
      id: id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
    );
  }
}
