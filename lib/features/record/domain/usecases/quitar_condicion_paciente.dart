import 'package:salud_dental_clinic_management/features/record/domain/repositories/record_repository.dart';

/// Quita la asociación entre una condición y el expediente del paciente.
class QuitarCondicionPaciente {
  final RecordRepository _repository;

  QuitarCondicionPaciente(this._repository);

  Future<void> call(String pacienteId, String condicionId) {
    return _repository.quitarCondicion(pacienteId, condicionId);
  }
}
