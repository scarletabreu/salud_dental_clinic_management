import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';

class DeleteCita {
  final CitaRepository _repository;

  DeleteCita(this._repository);

  Future<void> call(String id) async {
    if (id.isEmpty) {
      throw DeleteCitaException('El ID de la cita no puede estar vacío.');
    }
    await _repository.deleteCita(id);
  }
}

class DeleteCitaException implements Exception {
  final String message;
  const DeleteCitaException(this.message);

  @override
  String toString() => message;
}