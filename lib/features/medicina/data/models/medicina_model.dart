import '../../domain/entities/medicina.dart';
import '../../../contraindicacion/data/models/contraindicacion_model.dart';
import '../../domain/enums/efecto_secundario.dart';

class MedicinaModel extends Medicina {
  MedicinaModel({
    required super.id,
    required super.nombre,
    super.principioActivo,
    required super.contraindicaciones,
    super.efectosSecundarios = const [],
  });

  factory MedicinaModel.fromJson(Map<String, dynamic> json) {
    List<String> rawEfectosSecundarios = [];
    final efectosSecData = json['efectos_secundarios'];

    if (efectosSecData is List) {
      rawEfectosSecundarios = efectosSecData.map((e) => e.toString()).toList();
    } else if (efectosSecData is String && efectosSecData.isNotEmpty) {
      final cleaned = efectosSecData
          .replaceAll('{', '')
          .replaceAll('}', '')
          .trim();
      if (cleaned.isNotEmpty) {
        rawEfectosSecundarios = cleaned
            .split(',')
            .map((e) => e.trim())
            .toList();
      }
    }

    List<ContraindicacionModel> contras = [];
    if (json['contraindicaciones'] != null &&
        json['contraindicaciones'] is List) {
      final rawList = json['contraindicaciones'] as List;
      contras = rawList
          .where((item) => item != null && item is Map<String, dynamic>)
          .map(
            (item) =>
                ContraindicacionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    return MedicinaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      principioActivo: json['principio_activo'] as String?,
      contraindicaciones: contras,
      efectosSecundarios: rawEfectosSecundarios
          .map(
            (e) => EfectoSecundario.values.firstWhere(
              (val) => val.name.toLowerCase() == e.toLowerCase(),
              orElse: () => EfectoSecundario.inflamacion,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre.trim(),
      'principio_activo': principioActivo?.trim().isEmpty ?? true
          ? null
          : principioActivo!.trim(),
      'efectos_secundarios': efectosSecundarios.map((e) => e.name).toList(),
    };

    if (id != null &&
        id!.trim().isNotEmpty &&
        id!.length == 36 &&
        id!.contains('-') &&
        !id!.startsWith('temp-')) {
      data['id'] = id;
    }

    return data;
  }

  factory MedicinaModel.fromEntity(Medicina medicina) {
    return MedicinaModel(
      id: medicina.id,
      nombre: medicina.nombre,
      principioActivo: medicina.principioActivo,
      contraindicaciones: medicina.contraindicaciones,
      efectosSecundarios: medicina.efectosSecundarios,
    );
  }
}
