import 'package:salud_dental_clinic_management/features/documento_clinico/domain/enums/tipo_documento.dart';

class DocumentoClinico {
  final String id;
  final String pacienteId;
  final String consultaId;
  final String descripcion;
  final TipoDocumento tipoDocumento;
  final DateTime fechaCreacion;
  final String urlArchivo;

  DocumentoClinico({
    required this.id,
    required this.pacienteId,
    required this.consultaId,
    required this.descripcion,
    required this.tipoDocumento,
    required this.fechaCreacion,
    required this.urlArchivo,
  });
}
