import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/categoria_condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/tipo_condicion.dart';

class CondicionModel extends Condicion {
  CondicionModel({
    super.id,
    required super.nombre,
    required super.tipo,
    required super.categoria,
  });

  factory CondicionModel.fromJson(Map<String, dynamic> json) {
    return CondicionModel(
      id: json['id'] as String?,
      nombre: json['nombre'] as String,
      tipo: TipoCondicion.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoCondicion.alergica,
      ),
      categoria: CategoriaCondicion.values.firstWhere(
        (e) => e.name == json['categoria'],
        orElse: () => CategoriaCondicion.temporal,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'tipo': tipo.name,
      'categoria': categoria.name,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
