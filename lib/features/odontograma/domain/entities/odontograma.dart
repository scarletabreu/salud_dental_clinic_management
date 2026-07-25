import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/proyeccion_odontograma.dart';

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

  /// Lo anotado en el odontodiagrama de consultas anteriores del mismo
  /// paciente. Es un campo derivado —igual que `Diente.tratamientosHistoricos`—
  /// que se calcula al cargar y no se persiste: la fuente sigue siendo la
  /// `evaluacion` de cada consulta.
  final EvaluacionOdontologica evaluacionHistorica;

  Odontograma({
    this.id,
    required this.consultaId,
    required this.dientes,
    this.tratamientos = const [],
    this.diagnosis = const [],
    this.evaluacion = EvaluacionOdontologica.vacia,
    this.evaluacionHistorica = EvaluacionOdontologica.vacia,
  });

  Odontograma copyWith({
    String? consultaId,
    List<Diente>? dientes,
    List<Tratamiento>? tratamientos,
    List<Diagnosis>? diagnosis,
    EvaluacionOdontologica? evaluacion,
    EvaluacionOdontologica? evaluacionHistorica,
  }) {
    return Odontograma(
      id: id,
      consultaId: consultaId ?? this.consultaId,
      dientes: dientes ?? List.from(this.dientes),
      tratamientos: tratamientos ?? List.from(this.tratamientos),
      diagnosis: diagnosis ?? List.from(this.diagnosis),
      evaluacion: evaluacion ?? this.evaluacion,
      evaluacionHistorica: evaluacionHistorica ?? this.evaluacionHistorica,
    );
  }

  /// Persistencia residual de SD-141. Los hallazgos dentales se guardan en
  /// `diagnosticos_aplicados` / `tratamientos_aplicados`, no en este JSON.
  Map<String, dynamic> evaluacionToJson() => EvaluacionOdontologica(
    tejidosBlandos: evaluacion.tejidosBlandos,
  ).toJson();

  /// Datos visuales de las claves dentales más tejidos blandos. Nunca se
  /// persiste como JSON: la fuente de las claves son las filas normalizadas.
  EvaluacionOdontologica get evaluacionProyectada =>
      proyectarEvaluacionOdontologica(this);

  /// Lo mismo, pero como se ve *debajo* de otra consulta: solo diagnósticos,
  /// para que un tratamiento previo no se estampe en tenue sobre la pieza.
  EvaluacionOdontologica get evaluacionComoAntecedente =>
      proyectarEvaluacionOdontologica(this, soloDiagnosticos: true);
}
