import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import '../entities/record.dart';

abstract class RecordRepository {
  Future<Record> getRecordDelPaciente(String pacienteId);
  Future<void> actualizarRecord(Record record);
  Future<void> eliminarRecord(String id);

  // ── Condiciones médicas del paciente ──────────────────────────────────────

  /// Condiciones (del catálogo) registradas para el paciente. Lista vacía si el
  /// paciente aún no tiene expediente.
  Future<List<Condicion>> getCondicionesDelPaciente(String pacienteId);

  /// Asocia una condición del catálogo al paciente (crea el expediente si hace
  /// falta).
  Future<void> agregarCondicion(String pacienteId, String condicionId);

  /// Quita la asociación entre el paciente y la condición.
  Future<void> quitarCondicion(String pacienteId, String condicionId);
}
