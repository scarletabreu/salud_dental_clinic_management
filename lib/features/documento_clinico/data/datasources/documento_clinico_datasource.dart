abstract class DocumentoClinicoDatasource {
  Future<void> subirDocumento(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> fetchDocumentosPaciente(String pacienteId);
  Future<void> eliminarDocumento(String id);
}
