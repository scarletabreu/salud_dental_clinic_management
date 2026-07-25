import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';

class Odontograma {
  final String? id;
  final String consultaId;
  final List<Diente> dientes;
  final List<Tratamiento> tratamientos;
  final List<Diagnosis> diagnosis;
  final Map<int, HallazgoDental> hallazgos;
  final Map<TejidoBlando, EvaluacionTejidoBlando> tejidosBlandos;

  Odontograma({
    this.id,
    required this.consultaId,
    required this.dientes,
    this.tratamientos = const [],
    this.diagnosis = const [],
    this.hallazgos = const {},
    this.tejidosBlandos = const {},
  });

  Odontograma copyWith({
    String? consultaId,
    List<Diente>? dientes,
    List<Tratamiento>? tratamientos,
    List<Diagnosis>? diagnosis,
    Map<int, HallazgoDental>? hallazgos,
    Map<TejidoBlando, EvaluacionTejidoBlando>? tejidosBlandos,
  }) {
    return Odontograma(
      id: id,
      consultaId: consultaId ?? this.consultaId,
      dientes: dientes ?? List.from(this.dientes),
      tratamientos: tratamientos ?? List.from(this.tratamientos),
      diagnosis: diagnosis ?? List.from(this.diagnosis),
      hallazgos: hallazgos ?? Map.from(this.hallazgos),
      tejidosBlandos: tejidosBlandos ?? Map.from(this.tejidosBlandos),
    );
  }

  Map<String, dynamic> evaluacionToJson() => {
    'hallazgos': {
      for (final entry in hallazgos.entries)
        entry.key.toString(): entry.value.toJson(),
    },
    'tejidos_blandos': {
      for (final entry in tejidosBlandos.entries)
        entry.key.dbValue: entry.value.toJson(),
    },
  };
}
