import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/data/models/condicion_model.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart'
    as entity;
import 'package:salud_dental_clinic_management/features/record/domain/repositories/record_repository.dart';
import 'package:salud_dental_clinic_management/features/record/data/datasources/record_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/record/data/models/record_model.dart';

class RecordRepositoryImpl implements RecordRepository {
  final RecordRemoteDatasource remoteDataSource;

  RecordRepositoryImpl({required this.remoteDataSource});

  @override
  Future<entity.Record> getRecordDelPaciente(String pacienteId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchRecordByPaciente(pacienteId);

      if (data == null) {
        return RecordModel.empty().copyWith(pacienteId: pacienteId);
      }

      return RecordModel.fromJson(data);
    }, context: 'obtener el expediente');
  }

  @override
  Future<void> actualizarRecord(entity.Record record) {
    return runGuarded(() async {
      final data = RecordModel.fromEntity(record).toJson();

      data['deleted_at'] = null;
      data['updated_at'] = DateTime.now().toIso8601String();

      await remoteDataSource.upsertRecord(data);
    }, context: 'actualizar el expediente');
  }

  @override
  Future<void> eliminarRecord(String id) {
    return runGuarded(
      () => remoteDataSource.anularRecord(id),
      context: 'eliminar el expediente',
    );
  }

  @override
  Future<List<Condicion>> getCondicionesDelPaciente(String pacienteId) {
    return runGuarded(() async {
      final recordId = await remoteDataSource.fetchRecordId(pacienteId);
      if (recordId == null) return const <Condicion>[];

      final filas = await remoteDataSource.fetchAflicciones(recordId);
      return filas
          .where((f) => f['condiciones'] != null)
          .map((f) => CondicionModel.fromJson(
                Map<String, dynamic>.from(f['condiciones'] as Map),
              ))
          .toList();
    }, context: 'obtener las condiciones');
  }

  @override
  Future<void> agregarCondicion(String pacienteId, String condicionId) {
    return runGuarded(() async {
      final recordId = await remoteDataSource.getOrCreateRecordId(pacienteId);
      await remoteDataSource.addAfliccion(recordId, condicionId);
    }, context: 'agregar la condición');
  }

  @override
  Future<void> quitarCondicion(String pacienteId, String condicionId) {
    return runGuarded(() async {
      final recordId = await remoteDataSource.fetchRecordId(pacienteId);
      if (recordId == null) return;
      await remoteDataSource.removeAfliccion(recordId, condicionId);
    }, context: 'quitar la condición');
  }
}
