import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Distingue lo que el paciente ya traía de lo realizado en la consulta.
/// Solo los procedimientos de esta consulta pasan al eje de facturación.
enum OrigenMarcaOdontograma { preexistente, estaConsulta }

class DiagnosticoAplicado {
  final String? id;
  final String diagnosisId;
  final SeveridadDiagnosis severidad;
  final DateTime fechaAplicacion;
  final String notas;
  final String? consultaId;
  final String? dienteId;
  final TipoSuperficie? superficie;
  final OrigenMarcaOdontograma origen;

  /// Acto de evaluación (SD-135) al que pertenece el hallazgo. De él cuelga el
  /// doctor que lo anotó: el eje de evaluación no repite esa columna.
  final String? evaluacionId;

  /// Quién anotó el hallazgo. No es una columna propia: llega del JOIN con la
  /// evaluación y, a falta de ella, del doctor de la consulta. Se conserva en
  /// la entidad porque la ficha de la pieza tiene que poder mostrarlo (SD-142).
  final String? doctorId;

  /// Datos del catálogo incluidos por el JOIN; permiten proyectar el glifo sin
  /// convertir el catálogo en un mapa codificado en la interfaz.
  final String? nombreDiagnostico;
  final String? claveOdontograma;

  /// Cuándo se anuló el hallazgo (`deleted_at`). Se conserva porque retirar un
  /// hallazgo no borra que se anotó: la línea de tiempo de la pieza lo sigue
  /// contando, tachado (SD-144).
  final DateTime? anuladoEn;

  bool get estaAnulado => anuladoEn != null;

  DiagnosticoAplicado({
    this.id,
    required this.diagnosisId,
    required this.severidad,
    required this.fechaAplicacion,
    required this.notas,
    this.consultaId,
    this.dienteId,
    this.superficie,
    this.origen = OrigenMarcaOdontograma.preexistente,
    this.evaluacionId,
    this.doctorId,
    this.nombreDiagnostico,
    this.claveOdontograma,
    this.anuladoEn,
  });

  DiagnosticoAplicado copyWith({
    String? id,
    String? diagnosisId,
    SeveridadDiagnosis? severidad,
    DateTime? fechaAplicacion,
    String? notas,
    String? consultaId,
    String? dienteId,
    TipoSuperficie? superficie,
    OrigenMarcaOdontograma? origen,
    String? evaluacionId,
    String? doctorId,
    String? nombreDiagnostico,
    String? claveOdontograma,
    DateTime? anuladoEn,
  }) {
    return DiagnosticoAplicado(
      id: id ?? this.id,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      severidad: severidad ?? this.severidad,
      fechaAplicacion: fechaAplicacion ?? this.fechaAplicacion,
      notas: notas ?? this.notas,
      consultaId: consultaId ?? this.consultaId,
      dienteId: dienteId ?? this.dienteId,
      superficie: superficie ?? this.superficie,
      origen: origen ?? this.origen,
      evaluacionId: evaluacionId ?? this.evaluacionId,
      doctorId: doctorId ?? this.doctorId,
      nombreDiagnostico: nombreDiagnostico ?? this.nombreDiagnostico,
      claveOdontograma: claveOdontograma ?? this.claveOdontograma,
      anuladoEn: anuladoEn ?? this.anuladoEn,
    );
  }
}
