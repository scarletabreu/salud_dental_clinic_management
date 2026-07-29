import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';

class Contraindicacion {
  final String? id;
  final String condicionId;
  final String? medicinaId;
  final String? tratamientoId;
  final String? procedimientoId;
  final String descripcion;
  final TipoContraindicacion tipoContraindicacion;
  final List<EfectoAdverso> efectosAdversos;

  Contraindicacion({
    this.id,
    required this.condicionId,
    this.medicinaId,
    this.tratamientoId,
    this.procedimientoId,
    required this.descripcion,
    required this.tipoContraindicacion,
    required this.efectosAdversos,
  }) {
    final count = [
      medicinaId,
      tratamientoId,
      procedimientoId,
    ].where((e) => e != null && e.trim().isNotEmpty).length;

    if (count != 1) {
      throw ArgumentError(
        'Error de integridad: Una contraindicación debe estar vinculada exactamente a un medicinaId, tratamientoId o procedimientoId no vacío.',
      );
    }

    if (condicionId.trim().isEmpty || condicionId == 'TODO') {
      throw ArgumentError(
        'Error de integridad: Debe proporcionar un condicionId válido.',
      );
    }
  }

  Contraindicacion copyWith({
    String? condicionId,
    String? medicinaId,
    String? procedimientoId,
    String? tratamientoId,
    String? descripcion,
    TipoContraindicacion? tipoContraindicacion,
    List<EfectoAdverso>? efectosAdversos,
  }) {
    return Contraindicacion(
      id: id,
      condicionId: condicionId ?? this.condicionId,
      medicinaId: medicinaId ?? this.medicinaId,
      procedimientoId: procedimientoId ?? this.procedimientoId,
      tratamientoId: tratamientoId ?? this.tratamientoId,
      descripcion: descripcion ?? this.descripcion,
      tipoContraindicacion: tipoContraindicacion ?? this.tipoContraindicacion,
      efectosAdversos: efectosAdversos ?? this.efectosAdversos,
    );
  }
}
