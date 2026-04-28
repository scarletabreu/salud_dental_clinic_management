import 'package:salud_dental_clinic_management/features/record/data/datasources/record_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/record/data/models/record_model.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart'
    as entity; // Uso de alias para evitar confusión
import 'package:salud_dental_clinic_management/features/record/domain/repositories/record_repository.dart';

class RecordRepositoryImpl implements RecordRepository {
  final RecordRemoteDatasource remoteDataSource;

  RecordRepositoryImpl({required this.remoteDataSource});

  @override
  Future<entity.Record> getRecordDelPaciente(String pacienteId) async {
    final data = await remoteDataSource.fetchRecordByPaciente(pacienteId);

    if (data == null) {
      return RecordModel.empty().copyWith(pacienteId: pacienteId);
    }

    return RecordModel.fromJson(data);
  }

  @override
  Future<void> actualizarRecord(entity.Record record) async {
    final model = RecordModel.fromEntity(record);
    final data = model.toJson();

    data['deleted_at'] = null;
    data['updated_at'] = DateTime.now().toIso8601String();

    await remoteDataSource.upsertRecord(data);
  }

  @override
  Future<void> eliminarRecord(String id) async {
    await remoteDataSource.anularRecord(id);
  }
}
