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

  /// Odontodiagrama del formulario: hallazgos por pieza y tejidos blandos.
  /// Vive en `odontogramas.evaluacion_clinica` (jsonb), aparte de `dientes`,
  /// que sigue normalizado porque de él cuelgan tratamientos y facturación.
  final EvaluacionOdontologica evaluacion;

  Odontograma({
    this.id,
    required this.consultaId,
    required this.dientes,
    this.tratamientos = const [],
    this.diagnosis = const [],
    this.evaluacion = EvaluacionOdontologica.vacia,
  });

  Odontograma copyWith({
    String? consultaId,
    List<Diente>? dientes,
    List<Tratamiento>? tratamientos,
    List<Diagnosis>? diagnosis,
    EvaluacionOdontologica? evaluacion,
  }) {
    return Odontograma(
      id: id,
      consultaId: consultaId ?? this.consultaId,
      dientes: dientes ?? List.from(this.dientes),
      tratamientos: tratamientos ?? List.from(this.tratamientos),
      diagnosis: diagnosis ?? List.from(this.diagnosis),
      evaluacion: evaluacion ?? this.evaluacion,
    );
  }

  Map<String, dynamic> evaluacionToJson() => evaluacion.toJson();
}
