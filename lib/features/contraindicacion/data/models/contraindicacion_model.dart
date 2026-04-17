import '../../domain/entities/contraindicacion.dart';
import '../../domain/enums/condicion_medica.dart';
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

// Parses enum name or legacy hyphenated IDs (e.g. "cond-diabetes" → diabetes).
CondicionMedica? _parseCondicion(String? value) {
  if (value == null || value.isEmpty) return null;
  final normalized = value
      .toLowerCase()
      .replaceAll('cond-', '')
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
  for (final e in CondicionMedica.values) {
    final name = e.toString().split('.').last.toLowerCase();
    if (name == normalized) return e;
  }
  // Partial match for legacy IDs like "cond-alergia-penicilina"
  for (final e in CondicionMedica.values) {
    final name = e.toString().split('.').last.toLowerCase();
    if (normalized.contains(name) || name.contains(normalized)) return e;
  }
  return null;
}

class ContraindicacionModel extends Contraindicacion {
  ContraindicacionModel({
    required super.id,
    super.condicion,
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
      condicion: _parseCondicion(json['condicion_id'] as String?),
      medicinaId: json['medicina_id'] as String? ?? '',
      contraindicacionId: json['contraindicacion_id'] as String? ?? '',
      tratamientoId: json['tratamiento_id'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      tipoContraindicacion: _parseTipo(json['tipo_contraindicacion'] as String),
      efectosAdversos:
          (json['efectos_adversos'] as List<dynamic>?)
              ?.map((e) => _parseEfectoAdverso(e.toString()))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'condicion_id': condicion?.toString().split('.').last,
      'medicina_id': medicinaId,
      'contraindicacion_id': contraindicacionId,
      'tratamiento_id': tratamientoId,
      'descripcion': descripcion,
      'tipo_contraindicacion': tipoContraindicacion.toString().split('.').last,
      'efectos_adversos':
          efectosAdversos.map((e) => e.toString().split('.').last).toList(),
    };
  }

  factory ContraindicacionModel.fromEntity(Contraindicacion contraindicacion) {
    return ContraindicacionModel(
      id: contraindicacion.id,
      condicion: contraindicacion.condicion,
      medicinaId: contraindicacion.medicinaId,
      contraindicacionId: contraindicacion.contraindicacionId,
      tratamientoId: contraindicacion.tratamientoId,
      descripcion: contraindicacion.descripcion,
      tipoContraindicacion: contraindicacion.tipoContraindicacion,
      efectosAdversos: contraindicacion.efectosAdversos,
    );
  }
}
