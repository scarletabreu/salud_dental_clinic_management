import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';

class RecordCondicion {
  final String? id;
  final String recordId;
  final String condicionId;
  final Condicion? condicion;
  final String? medicamento;
  final String? dosis;
  final String? frecuencia;
  final String? medicoTratante;
  final String? contactoMedico;
  final String? notas;
  final bool activo;
  final DateTime? fechaDeteccion;

  const RecordCondicion({
    this.id,
    required this.recordId,
    required this.condicionId,
    this.condicion,
    this.medicamento,
    this.dosis,
    this.frecuencia,
    this.medicoTratante,
    this.contactoMedico,
    this.notas,
    this.activo = true,
    this.fechaDeteccion,
  });

  RecordCondicion copyWith({
    String? id,
    String? recordId,
    String? condicionId,
    Condicion? condicion,
    String? medicamento,
    String? dosis,
    String? frecuencia,
    String? medicoTratante,
    String? contactoMedico,
    String? notas,
    bool? activo,
    DateTime? fechaDeteccion,
  }) {
    return RecordCondicion(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      condicionId: condicionId ?? this.condicionId,
      condicion: condicion ?? this.condicion,
      medicamento: medicamento ?? this.medicamento,
      dosis: dosis ?? this.dosis,
      frecuencia: frecuencia ?? this.frecuencia,
      medicoTratante: medicoTratante ?? this.medicoTratante,
      contactoMedico: contactoMedico ?? this.contactoMedico,
      notas: notas ?? this.notas,
      activo: activo ?? this.activo,
      fechaDeteccion: fechaDeteccion ?? this.fechaDeteccion,
    );
  }
}
