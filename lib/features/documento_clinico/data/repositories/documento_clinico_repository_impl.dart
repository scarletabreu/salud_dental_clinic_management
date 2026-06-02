import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/repositories/documento_clinico_repository.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/data/datasources/documento_clinico_datasource.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/data/models/documento_clinico_model.dart';

class DocumentoClinicoRepositoryImpl implements DocumentoClinicoRepository {
  final DocumentoClinicoDatasource remoteDataSource;

  DocumentoClinicoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> registrarDocumento(DocumentoClinico documento) async {
    try {
      final model = DocumentoClinicoModel(
        id: documento.id,
        consultaId: documento.consultaId,
        pacienteId: documento.pacienteId,
        descripcion: documento.descripcion,
        tipoDocumento: documento.tipoDocumento,
        fechaCreacion: documento.fechaCreacion,
        urlArchivo: documento.urlArchivo,
      );
      await remoteDataSource.subirDocumento(model.toJson());
    } catch (e) {
      throw Exception(
        'Error en el repositorio al registrar documento clínico: $e',
      );
    }
  }

  @override
  Future<List<DocumentoClinico>> getDocumentosPaciente(
    String pacienteId,
  ) async {
    try {
      final data = await remoteDataSource.fetchDocumentosPaciente(pacienteId);
      return data.map((json) => DocumentoClinicoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener documentos del paciente: $e',
      );
    }
  }

  @override
  Future<void> borrarDocumento(String id) async {
    try {
      await remoteDataSource.eliminarDocumento(id);
    } catch (e) {
      throw Exception(
        'Error en el repositorio al borrar documento clínico: $e',
      );
    }
  }
}
