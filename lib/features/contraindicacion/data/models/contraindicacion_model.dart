import '../../domain/entities/contraindicacion.dart';
import '../../domain/enums/efecto_adverso.dart';
import '../../domain/enums/tipo_contraindicacion.dart';

class ContraindicacionModel extends Contraindicacion {
  ContraindicacionModel({
    required super.id,
    required super.condicionId,
    required super.medicinaId,
    required super.contraindicacionId,
    required super.tratamientoId,
    required super.descripcion,
    required super.tipoContraindicacion,
    required super.efectosAdversos,
  });

  factory ContraindicacionModel.fromJson(Map<String, dynamic> json) {
    return ContraindicacionModel(
      id: json['id'] as String,
      condicionId: json['condicion_id'] as String,
      medicinaId: json['medicina_id'] as String,
      contraindicacionId: json['contraindicacion_id'] as String,
      tratamientoId: json['tratamiento_id'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      tipoContraindicacion: TipoContraindicacion.values.byName(
        json['tipo_contraindicacion'] as String,
      ),
      efectosAdversos:
          (json['efectos_adversos'] as List<dynamic>?)
              ?.map((e) => EfectoAdverso.values.byName(e.toString()))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'condicion_id': condicionId,
      'medicina_id': medicinaId,
      'contraindicacion_id': contraindicacionId,
      'tratamiento_id': tratamientoId,
      'descripcion': descripcion,
      'tipo_contraindicacion': tipoContraindicacion.name,
      'efectos_adversos': efectosAdversos.map((e) => e.name).toList(),
    };
  }

  factory ContraindicacionModel.fromEntity(Contraindicacion contraindicacion) {
    return ContraindicacionModel(
      id: contraindicacion.id,
      condicionId: contraindicacion.condicionId,
      medicinaId: contraindicacion.medicinaId,
      contraindicacionId: contraindicacion.contraindicacionId,
      tratamientoId: contraindicacion.tratamientoId,
      descripcion: contraindicacion.descripcion,
      tipoContraindicacion: contraindicacion.tipoContraindicacion,
      efectosAdversos: contraindicacion.efectosAdversos,
    );
  }
}
