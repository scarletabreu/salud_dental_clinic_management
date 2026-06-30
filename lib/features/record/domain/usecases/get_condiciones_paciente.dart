import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/record/domain/repositories/record_repository.dart';

/// Lista las condiciones médicas registradas para un paciente.
class GetCondicionesPaciente {
  final RecordRepository _repository;

  GetCondicionesPaciente(this._repository);

  Future<List<Condicion>> call(String pacienteId) {
    return _repository.getCondicionesDelPaciente(pacienteId);
  }
}
