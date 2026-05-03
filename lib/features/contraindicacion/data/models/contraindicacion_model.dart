import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';

class ContraindicacionModel extends Contraindicacion {
  ContraindicacionModel({
    super.id,
    required super.condicionId,
    super.medicinaId,
    super.contraindicacionId,
    super.tratamientoId,
    required super.descripcion,
    required super.tipoContraindicacion,
    required super.efectosAdversos,
  });

  factory ContraindicacionModel.fromJson(Map<String, dynamic> json) {
    return ContraindicacionModel(
      id: json['id'] as String?,
      condicionId: json['condicion_id'] as String? ?? '',
      medicinaId: json['medicina_id'] as String?,
      contraindicacionId: json['contraindicacion_id'] as String?,
      tratamientoId: json['tratamiento_id'] as String?,
      descripcion: json['descripcion'] as String? ?? '',
      tipoContraindicacion: TipoContraindicacion.fromKey(
        json['tipo_contraindicacion'] as String,
      ),
      efectosAdversos:
          (json['efectos_adversos'] as List?)
              ?.map(
                (e) => EfectoAdverso.values.firstWhere(
                  (v) => v.name == e,
                  orElse: () => EfectoAdverso.fatiga,
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'condicion_id': condicionId,
      'medicina_id': medicinaId,
      'contraindicacion_id': contraindicacionId,
      'tratamiento_id': tratamientoId,
      'descripcion': descripcion,
      'tipo_contraindicacion': tipoContraindicacion.key,
      'efectos_adversos': efectosAdversos.map((e) => e.name).toList(),
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
