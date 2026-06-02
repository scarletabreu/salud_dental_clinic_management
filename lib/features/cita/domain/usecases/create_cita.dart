import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';

/// Caso de uso: crear una nueva cita.
///
/// Encapsula la validación de negocio antes de delegar al repositorio,
/// siguiendo el mismo patrón de AddMedicina / UpdateMedicina del proyecto.
class CreateCita {
  final CitaRepository _repository;

  CreateCita(this._repository);

  /// Lanza [CreateCitaException] si la validación falla.
  /// De lo contrario persiste la cita y retorna normalmente.
  Future<void> call(Cita cita) async {
    // ── Regla 1: no agendar en el pasado ────────────────────────────────────
    if (cita.date.isBefore(DateTime.now().toUtc())) {
      throw CreateCitaException(
        'No se puede programar una cita en una fecha y hora pasada.',
      );
    }

    // ── Regla 2: campos obligatorios ─────────────────────────────────────────
    if (cita.persona.id == null || cita.persona.id!.isEmpty) {
      throw CreateCitaException('La cita debe estar asociada a una persona.');
    }

    await _repository.createCita(cita);
  }
}

class CreateCitaException implements Exception {
  final String message;
  const CreateCitaException(this.message);

  @override
  String toString() => message;
}