import '../../domain/entities/medicina.dart';
import '../../../contraindicacion/data/models/contraindicacion_model.dart';
import '../../domain/enums/efecto_secundario.dart';

class MedicinaModel extends Medicina {
  MedicinaModel({
    required super.id,
    required super.nombre,
    required super.contraindicaciones,
    super.efectosSecundarios = const [],
  });

  factory MedicinaModel.fromJson(Map<String, dynamic> json) {
    return MedicinaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      contraindicaciones:
          (json['contraindicaciones'] as List?)
              ?.map((c) => ContraindicacionModel.fromJson(c))
              .toList() ??
          [],
      efectosSecundarios:
          (json['efectos_secundarios'] as List?)
              ?.map(
                (e) => EfectoSecundario.values.firstWhere(
                  (val) => val.name == e,
                  orElse: () => EfectoSecundario.inflamacion,
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'efectos_secundarios': efectosSecundarios.map((e) => e.name).toList(),
    };
    if (id != null && id!.length == 36 && id!.contains('-')) {
      data['id'] = id;
    }

    return data;
  }

  factory MedicinaModel.fromEntity(Medicina medicina) {
    return MedicinaModel(
      id: medicina.id,
      nombre: medicina.nombre,
      contraindicaciones: medicina.contraindicaciones,
      efectosSecundarios: medicina.efectosSecundarios,
    );
  }
}
