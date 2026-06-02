import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';

class GetCitas {
  final CitaRepository _repository;

  GetCitas(this._repository);

  Future<List<Cita>> call() async {
    return _repository.getCitas();
  }
}