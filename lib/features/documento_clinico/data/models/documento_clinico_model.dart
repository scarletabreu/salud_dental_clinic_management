import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/enums/tipo_documento.dart';

class DocumentoClinicoModel extends DocumentoClinico {
  DocumentoClinicoModel({
    super.id,
    required super.consultaId,
    required super.pacienteId,
    required super.descripcion,
    required super.tipoDocumento,
    required super.fechaCreacion,
    required super.urlArchivo,
  });

  factory DocumentoClinicoModel.fromJson(Map<String, dynamic> json) {
    return DocumentoClinicoModel(
      id: json['id'] as String?,
      pacienteId: json['paciente_id'] ?? json['pacienteId'],
      consultaId: json['consulta_id'] ?? json['consultaId'],
      descripcion: json['descripcion'] as String,
      tipoDocumento: TipoDocumento.values.byName(
        json['tipo_documento'] ?? json['tipoDocumento'],
      ),
      fechaCreacion: DateTime.parse(
        json['fecha_creacion'] ?? json['fechaCreacion'],
      ),
      urlArchivo: json['url_archivo'] ?? json['urlArchivo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'paciente_id': pacienteId,
      'consulta_id': consultaId,
      'descripcion': descripcion,
      'tipo_documento': tipoDocumento.name,
      'fecha_creacion': fechaCreacion.toUtc().toIso8601String(),
      'url_archivo': urlArchivo,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
