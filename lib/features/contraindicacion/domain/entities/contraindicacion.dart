import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/condicion_medica.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';

class Contraindicacion {
  final String id;
  final String condicionId;
  final String? medicinaId;
  final String? contraindicacionId;
  final String? tratamientoId;
  final String descripcion;
  final TipoContraindicacion tipoContraindicacion;
  final List<EfectoAdverso> efectosAdversos;

  Contraindicacion._({
    required this.id,
    required this.condicionId,
    required this.medicinaId,
    required this.contraindicacionId,
    required this.tratamientoId,
    required this.descripcion,
    required this.tipoContraindicacion,
    required this.efectosAdversos,
  });

  factory Contraindicacion({
    required String id,
    required String condicionId,
    String? medicinaId,
    String? contraindicacionId,
    String? tratamientoId,
    required String descripcion,
    required TipoContraindicacion tipoContraindicacion,
    required List<EfectoAdverso> efectosAdversos,
  }) {
    final count = [medicinaId, contraindicacionId, tratamientoId]
        .where((e) => e != null)
        .length;

    if (count != 1) {
      throw ArgumentError(
        'Debe existir exactamente uno entre medicinaId, contraindicacionId o tratamientoId',
      );
    }

    return Contraindicacion._(
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

  Contraindicacion copyWith({
    String? condicionId,
    String? medicinaId,
    String? contraindicacionId,
    String? tratamientoId,
    String? descripcion,
    TipoContraindicacion? tipoContraindicacion,
    List<EfectoAdverso>? efectosAdversos,
  }) {
    final newMedicinaId = medicinaId ?? this.medicinaId;
    final newContraindicacionId = contraindicacionId ?? this.contraindicacionId;
    final newTratamientoId = tratamientoId ?? this.tratamientoId;

    final count = [
      newMedicinaId,
      newContraindicacionId,
      newTratamientoId
    ].where((e) => e != null).length;

    if (count != 1) {
      throw ArgumentError(
        'Debe existir exactamente uno entre medicinaId, contraindicacionId o tratamientoId',
      );
    }

    return Contraindicacion._(
      id: id,
      condicionId: condicionId ?? this.condicionId,
      medicinaId: newMedicinaId,
      contraindicacionId: newContraindicacionId,
      tratamientoId: newTratamientoId,
      descripcion: descripcion ?? this.descripcion,
      tipoContraindicacion:
          tipoContraindicacion ?? this.tipoContraindicacion,
      efectosAdversos: efectosAdversos ?? this.efectosAdversos,
    );
  }

  factory Contraindicacion.fromJson(Map<String, dynamic> json) {
    return Contraindicacion(
      id: json['id'] as String,
      condicionId: json['condicionId'] as String,
      medicinaId: json['medicinaId'] as String?,
      contraindicacionId: json['contraindicacionId'] as String?,
      tratamientoId: json['tratamientoId'] as String?,
      descripcion: json['descripcion'] as String,
      tipoContraindicacion: TipoContraindicacion.values
          .byName(json['tipoContraindicacion'] as String),
      efectosAdversos: (json['efectosAdversos'] as List<dynamic>? ?? [])
          .map((e) => EfectoAdverso.values.byName(e as String))
          .toList(),
    );
  }
}