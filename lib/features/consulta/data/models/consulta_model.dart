import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/data/models/documento_clinico_model.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/models/odontograma_model.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';

class ConsultaModel extends Consulta {
  ConsultaModel({
    required super.id,
    required super.pacienteId,
    required super.doctorId,
    required super.citaId,
    required super.fecha,
    super.recetas,
    super.documentosClinicos,
    super.odontograma,
    super.tempCondiciones,
    super.motivoConsulta,
  });

  factory ConsultaModel.fromJson(Map<String, dynamic> json) {
    return ConsultaModel(
      id: json['id'],
      pacienteId: json['paciente_id'] ?? json['pacienteId'],
      doctorId: json['doctor_id'] ?? json['doctorId'],
      citaId: json['cita_id'] ?? json['citaId'],
      fecha: DateTime.parse(json['fecha']).toLocal(),
      motivoConsulta: json['motivo_consulta'] ?? json['motivoConsulta'],
      recetas: json['recetas'] != null
          ? (json['recetas'] as List)
                .map((x) => RecetaModel.fromJson(x))
                .toList()
          : [],
      documentosClinicos:
          json['documentos_clinicos'] != null ||
              json['documentosClinicos'] != null
          ? (json['documentosClinicos'] ?? json['documentos_clinicos'] as List)
                .map((x) => DocumentoClinicoModel.fromJson(x))
                .toList()
          : [],
      odontograma: json['odontograma'] != null
          ? OdontogramaModel.fromJson(json['odontograma'])
          : null,
      tempCondiciones:
          json['temp_condiciones'] != null || json['tempCondiciones'] != null
          ? List<String>.from(
              json['tempCondiciones'] ?? json['temp_condiciones'],
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paciente_id': pacienteId,
      'doctor_id': doctorId,
      'cita_id': citaId,
      'fecha': fecha.toUtc().toIso8601String(),
      'motivo_consulta': motivoConsulta,
      'recetas': recetas.map((x) => (x as RecetaModel).toJson()).toList(),
      'documentos_clinicos': documentosClinicos
          .map((x) => (x as DocumentoClinicoModel).toJson())
          .toList(),
      'odontograma': (odontograma as OdontogramaModel?)?.toJson(),
      'temp_condiciones': tempCondiciones,
    };
  }
}
