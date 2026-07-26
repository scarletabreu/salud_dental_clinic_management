import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/data/models/documento_clinico_model.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/models/odontograma_model.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';

class ConsultaModel extends Consulta {
  ConsultaModel({
    super.id,
    required super.pacienteId,
    required super.doctorId,
    super.citaId,
    required super.fecha,
    super.recetas,
    super.documentosClinicos,
    super.odontograma,
    super.tempCondiciones,
    super.motivoConsulta,
    super.notas,
    super.signosVitales,
    super.finalizada,
    super.tipoAtencion,
    super.tienePreFactura,
  });

  factory ConsultaModel.fromJson(Map<String, dynamic> json) {
    return ConsultaModel(
      id: json['id'] as String?,
      pacienteId: (json['paciente_id'] ?? json['pacienteId'] ?? '') as String,
      doctorId: (json['doctor_id'] ?? json['doctorId'] ?? '') as String,
      citaId: json['cita_id'] ?? json['citaId'],
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      motivoConsulta: json['motivo_consulta'] ?? json['motivoConsulta'],
      notas: json['notas'] as String?,
      finalizada: (json['finalizada'] ?? false) as bool,
      tipoAtencion: TipoAtencionClinica.fromDb(
        json['tipo_atencion'] as String?,
      ),
      signosVitales: json['signos_vitales'] != null
          ? SignosVitales.fromJson(
              json['signos_vitales'] as Map<String, dynamic>,
            )
          : null,
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
      odontograma: _parseOdontograma(json['odontograma']),
      tempCondiciones: json['temp_condiciones'] != null
          ? List<String>.from(json['temp_condiciones'])
          : [],
      tienePreFactura:
          (json['tiene_pre_factura'] ?? json['tienePreFactura'] ?? false)
              as bool,
    );
  }

  static OdontogramaModel? _parseOdontograma(dynamic raw) {
    if (raw is Map<String, dynamic>) return OdontogramaModel.fromJson(raw);
    if (raw is List && raw.isNotEmpty) {
      return OdontogramaModel.fromJson(raw.first as Map<String, dynamic>);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'paciente_id': pacienteId,
      'doctor_id': doctorId,
      'cita_id': citaId,
      'fecha': fecha.toUtc().toIso8601String(),
      'motivo_consulta': motivoConsulta,
      'temp_condiciones': tempCondiciones,
      'signos_vitales': signosVitales?.toJson(),
      'finalizada': finalizada,
      'tipo_atencion': tipoAtencion.name,
      'tiene_pre_factura': tienePreFactura,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
