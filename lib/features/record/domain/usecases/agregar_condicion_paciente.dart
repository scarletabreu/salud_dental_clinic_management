import 'package:salud_dental_clinic_management/features/record/domain/repositories/record_repository.dart';

/// Asocia una condición del catálogo al expediente del paciente.
class AgregarCondicionPaciente {
  final RecordRepository _repository;

  AgregarCondicionPaciente(this._repository);

  Future<void> call(String pacienteId, String condicionId) {
    return _repository.agregarCondicion(pacienteId, condicionId);
  }
}
