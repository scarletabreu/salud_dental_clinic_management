import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/repositories/documento_clinico_repository.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/data/datasources/documento_clinico_datasource.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/data/models/documento_clinico_model.dart';

class DocumentoClinicoRepositoryImpl implements DocumentoClinicoRepository {
  final DocumentoClinicoDatasource remoteDataSource;

  DocumentoClinicoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> registrarDocumento(DocumentoClinico documento) {
    return runGuarded(() async {
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
    }, context: 'registrar el documento clínico');
  }

  @override
  Future<List<DocumentoClinico>> getDocumentosPaciente(String pacienteId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchDocumentosPaciente(pacienteId);
      return data.map((json) => DocumentoClinicoModel.fromJson(json)).toList();
    }, context: 'obtener los documentos del paciente');
  }

  @override
  Future<void> borrarDocumento(String id) {
    return runGuarded(
      () => remoteDataSource.eliminarDocumento(id),
      context: 'borrar el documento clínico',
    );
  }
}
