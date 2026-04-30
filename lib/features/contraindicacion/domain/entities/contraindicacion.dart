import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/tipo_contraindicacion.dart';

class Contraindicacion {
  final String id;
  final String condicionId;
  final String? medicinaId;
  final String? contraindicacionId;
  final String? tratamientoId;
  final String descripcion;
  final TipoContraindicacion tipoContraindicacion;
  final List<EfectoAdverso> efectosAdversos;

  Contraindicacion({
    required this.id,
    required this.condicionId,
    this.medicinaId,
    this.contraindicacionId,
    this.tratamientoId,
    required this.descripcion,
    required this.tipoContraindicacion,
    required this.efectosAdversos,
  }) {
    final count = [
      medicinaId,
      contraindicacionId,
      tratamientoId,
    ].where((e) => e != null).length;

    if (count != 1) {
      throw ArgumentError(
        'Error de integridad: Una contraindicación debe estar vinculada exactamente a una medicinaId, contraindicacionId o tratamientoId.',
      );
    }
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
    return Contraindicacion(
      id: id,
      condicionId: condicionId ?? this.condicionId,
      medicinaId: medicinaId ?? this.medicinaId,
      contraindicacionId: contraindicacionId ?? this.contraindicacionId,
      tratamientoId: tratamientoId ?? this.tratamientoId,
      descripcion: descripcion ?? this.descripcion,
      tipoContraindicacion: tipoContraindicacion ?? this.tipoContraindicacion,
      efectosAdversos: efectosAdversos ?? this.efectosAdversos,
    );
  }
}
