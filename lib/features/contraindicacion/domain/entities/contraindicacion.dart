import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/condicion_medica.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';

class Contraindicacion {
  final String id;
  final CondicionMedica? condicion;
  final String medicinaId;
  final String contraindicacionId;
  final String tratamientoId;
  final String descripcion;
  final TipoContraindicacion tipoContraindicacion;
  final List<EfectoAdverso> efectosAdversos;

  Contraindicacion({
    required this.id,
    this.condicion,
    required this.medicinaId,
    required this.contraindicacionId,
    required this.tratamientoId,
    required this.descripcion,
    required this.tipoContraindicacion,
    required this.efectosAdversos,
  });

  Contraindicacion copyWith({
    CondicionMedica? condicion,
    bool clearCondicion = false,
    String? medicinaId,
    String? contraindicacionId,
    String? tratamientoId,
    String? descripcion,
    TipoContraindicacion? tipoContraindicacion,
    List<EfectoAdverso>? efectosAdversos,
  }) {
    return Contraindicacion(
      id: id,
      condicion: clearCondicion ? null : (condicion ?? this.condicion),
      medicinaId: medicinaId ?? this.medicinaId,
      contraindicacionId: contraindicacionId ?? this.contraindicacionId,
      tratamientoId: tratamientoId ?? this.tratamientoId,
      descripcion: descripcion ?? this.descripcion,
      tipoContraindicacion: tipoContraindicacion ?? this.tipoContraindicacion,
      efectosAdversos: efectosAdversos ?? this.efectosAdversos,
    );
  }
}
