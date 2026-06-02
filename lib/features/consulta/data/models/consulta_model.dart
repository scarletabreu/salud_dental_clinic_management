import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/data/models/documento_clinico_model.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/models/odontograma_model.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';

class ConsultaModel extends Consulta {
  ConsultaModel({
    super.id,
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
      id: json['id'] as String?,
      pacienteId: json['paciente_id'] ?? json['pacienteId'],
      doctorId: json['doctor_id'] ?? json['doctorId'],
      citaId: json['cita_id'] ?? json['citaId'],
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      motivoConsulta: json['motivo_consulta'] ?? json['motivoConsulta'],
      recetas: json['recetas'] != null
          ? (json['recetas'] as List)
                .map((x) => RecetaModel.fromJson(x))
                .toList()
          : [],
      documentosClinicos: json['documentos_clinicos'] != null
          ? (json['documentos_clinicos'] as List)
                .map((x) => DocumentoClinicoModel.fromJson(x))
                .toList()
          : [],
      odontograma: json['odontograma'] != null
          ? OdontogramaModel.fromJson(json['odontograma'])
          : null,
      tempCondiciones: json['temp_condiciones'] != null
          ? List<String>.from(json['temp_condiciones'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'paciente_id': pacienteId,
      'doctor_id': doctorId,
      'cita_id': citaId,
      'fecha': fecha.toUtc().toIso8601String(),
      'motivo_consulta': motivoConsulta,
      'temp_condiciones': tempCondiciones,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
