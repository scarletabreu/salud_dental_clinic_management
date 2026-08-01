import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/models/diagnostico_aplicado_model.dart';
import 'package:salud_dental_clinic_management/features/superficie/data/models/superficie_model.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/models/tratamiento_aplicado_model.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/models/alcance_registro_clinico.dart';

class DienteModel extends Diente {
  DienteModel({
    super.id,
    required super.odontogramaId,
    required super.superficies,
    super.tratamientos = const [],
    super.tratamientosAplicadosIds = const [],
    super.diagnosis = const [],
    required super.fdiCode,
    super.observaciones,
    super.estaAusente = false,
  });

  factory DienteModel.fromJson(Map<String, dynamic> json) {
    final tratamientos =
        [
              for (final raw in json['tratamientos'] as List? ?? const [])
                if (raw is Map) Map<String, dynamic>.from(raw),
            ]
            .where(
              (fila) =>
                  !registroClinicoEsGeneral(fila, catalogoKey: 'tratamiento'),
            )
            .toList();
    final diagnosticos =
        [
              for (final raw in json['diagnosis'] as List? ?? const [])
                if (raw is Map) Map<String, dynamic>.from(raw),
            ]
            .where(
              (fila) =>
                  !registroClinicoEsGeneral(fila, catalogoKey: 'diagnosis'),
            )
            .toList();

    return DienteModel(
      id: json['id'] as String?,
      odontogramaId: (json['odontograma_id'] ?? '') as String,
      fdiCode: (json['fdi_code'] as num).toInt(),
      observaciones: json['observaciones'] as String?,
      estaAusente: json['esta_ausente'] as bool? ?? false,
      // Con la relación cargada, las filas normalizadas son la verdad. El
      // arreglo auxiliar también contiene registros históricos de arcada que
      // antes se pegaron a una pieza y haría reaparecerlos en su resumen.
      tratamientosAplicadosIds: json.containsKey('tratamientos')
          ? [
              for (final fila in tratamientos)
                if (fila['id'] is String) fila['id'] as String,
            ]
          : json['tratamientos_aplicados_ids'] != null
          ? (json['tratamientos_aplicados_ids'] as List)
                .whereType<String>()
                .toList()
          : const [],
      // Relaciones normalmente cargadas en una consulta con JOIN
      superficies: json['superficies'] != null
          ? (json['superficies'] as List)
                .map((e) => SuperficieModel.fromJson(e))
                .toList()
          : [],
      diagnosis: diagnosticos.map(DiagnosticoAplicadoModel.fromJson).toList(),
      tratamientos: tratamientos
          .map(TratamientoAplicadoModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'odontograma_id': odontogramaId,
      'fdi_code': fdiCode,
      'observaciones': observaciones,
      'esta_ausente': estaAusente,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
