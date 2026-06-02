import '../entities/record.dart';

abstract class RecordRepository {
  Future<Record> getRecordDelPaciente(String pacienteId);
  Future<void> actualizarRecord(Record record);
  Future<void> eliminarRecord(String id);
}
