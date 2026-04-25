import '../../domain/entities/contraindicacion.dart';
import '../../domain/enums/efecto_adverso.dart';
import '../../domain/enums/tipo_contraindicacion.dart';

// Parses either the Dart identifier ("absoluta") or the legacy display name ("Absoluta").
TipoContraindicacion _parseTipo(String value) {
  final lower = value.toLowerCase();
  for (final e in TipoContraindicacion.values) {
    if (e.toString().split('.').last == lower) return e;
    if (e.name.toLowerCase() == lower) return e;
  }
  throw ArgumentError('Unknown TipoContraindicacion: $value');
}

// Parses either identifier ("nauseas") or legacy display name ("Náuseas").
EfectoAdverso _parseEfectoAdverso(String value) {
  final lower = value.toLowerCase();
  for (final e in EfectoAdverso.values) {
    if (e.toString().split('.').last == lower) return e;
    if (e.name.toLowerCase() == lower) return e;
  }
  throw ArgumentError('Unknown EfectoAdverso: $value');
}

class ContraindicacionModel {
  final String id;
  final String condicionId;
  final String? medicinaId;
  final String? contraindicacionId;
  final String? tratamientoId;
  final String descripcion;
  final TipoContraindicacion tipoContraindicacion;
  final List<EfectoAdverso> efectosAdversos;

  ContraindicacionModel({
    required this.id,
    required this.condicionId,
    this.medicinaId,
    this.contraindicacionId,
    this.tratamientoId,
    required this.descripcion,
    required this.tipoContraindicacion,
    required this.efectosAdversos,
  });

  factory ContraindicacionModel.fromJson(Map<String, dynamic> json) {
    return ContraindicacionModel(
      id: json['id'],
      condicionId: json['condicion_id'],
      medicinaId: json['medicina_id'],
      contraindicacionId: json['contraindicacion_id'],
      tratamientoId: json['tratamiento_id'],
      descripcion: json['descripcion'],
      tipoContraindicacion:
          TipoContraindicacion.values.byName(json['tipo_contraindicacion']),
      efectosAdversos: (json['efectos_adversos'] as List<dynamic>? ?? [])
          .map((e) => EfectoAdverso.values.byName(e))
          .toList(),
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

  factory ContraindicacionModel.fromEntity(
  Contraindicacion contraindicacion,
) {
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

  Contraindicacion toEntity() {
    return Contraindicacion(
      id: id,
      condicionId: condicionId,
      medicinaId: medicinaId,
      contraindicacionId: contraindicacionId,
      tratamientoId: tratamientoId,
      descripcion: descripcion,
      tipoContraindicacion: tipoContraindicacion,
      efectosAdversos: efectosAdversos,
    );
  }
}