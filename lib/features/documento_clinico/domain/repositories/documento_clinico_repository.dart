import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';

abstract class DocumentoClinicoRepository {
  Future<void> registrarDocumento(DocumentoClinico documento);
  Future<List<DocumentoClinico>> getDocumentosPaciente(String pacienteId);
  Future<void> borrarDocumento(String id);
}
