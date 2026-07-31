import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/auditoria/data/datasources/auditoria_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/auditoria/data/models/evento_auditoria_model.dart';
import 'package:salud_dental_clinic_management/features/auditoria/domain/entities/evento_auditoria.dart';
import 'package:salud_dental_clinic_management/features/auditoria/domain/repositories/auditoria_repository.dart';

class AuditoriaRepositoryImpl implements AuditoriaRepository {
  final AuditoriaRemoteDatasource remoteDataSource;

  AuditoriaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<EventoAuditoria>> getLineaTiempo(String consultaId) {
    return runGuarded(() async {
      final filas = await remoteDataSource.fetchLineaTiempo(consultaId);
      return filas.map(EventoAuditoriaModel.fromJson).toList();
    }, context: 'obtener la línea de tiempo de la consulta');
  }
}
