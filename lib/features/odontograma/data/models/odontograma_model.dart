import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/diente/data/models/diente_model.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/data/models/diagnosis_model.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/data/models/tratamiento_model.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';

class OdontogramaModel extends Odontograma {
  OdontogramaModel({
    super.id,
    required super.consultaId,
    required super.dientes,
    super.tratamientos = const [],
    super.diagnosis = const [],
    super.hallazgos = const {},
    super.tejidosBlandos = const {},
  });

  factory OdontogramaModel.fromJson(Map<String, dynamic> json) {
    return OdontogramaModel(
      id: json['id'] as String?,
      consultaId: (json['consulta_id'] ?? json['consultaId'] ?? '') as String,
      dientes: json['dientes'] != null
          ? (json['dientes'] as List)
                .map((e) => DienteModel.fromJson(e))
                .toList()
          : [],
      tratamientos: json['tratamientos'] != null
          ? (json['tratamientos'] as List)
                .map((e) => TratamientoModel.fromJson(e))
                .toList()
          : [],
      diagnosis: json['diagnosis'] != null
          ? (json['diagnosis'] as List)
                .map((e) => DiagnosisModel.fromJson(e))
                .toList()
          : [],
      hallazgos: _parseHallazgos(json['evaluacion_clinica']),
      tejidosBlandos: _parseTejidos(json['evaluacion_clinica']),
    );
  }

  static Map<int, HallazgoDental> _parseHallazgos(dynamic raw) {
    final evaluacion = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    final hallazgos = evaluacion['hallazgos'];
    if (hallazgos is! Map) return const {};
    return {
      for (final entry in hallazgos.entries)
        if (int.tryParse(entry.key.toString()) != null && entry.value is Map)
          int.parse(entry.key.toString()): HallazgoDental.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          ),
    };
  }

  static Map<TejidoBlando, EvaluacionTejidoBlando> _parseTejidos(dynamic raw) {
    final evaluacion = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    final tejidos = evaluacion['tejidos_blandos'];
    if (tejidos is! Map) return const {};
    return {
      for (final tejido in TejidoBlando.values)
        if (tejidos[tejido.dbValue] is Map)
          tejido: EvaluacionTejidoBlando.fromJson(
            Map<String, dynamic>.from(tejidos[tejido.dbValue] as Map),
          ),
    };
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'consulta_id': consultaId,
      'evaluacion_clinica': evaluacionToJson(),
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
