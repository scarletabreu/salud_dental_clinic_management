import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';

abstract class CitaRepository {
  Future<List<Cita>> getCitas();
  Future<List<Cita>> getCitasByPaciente(String pacienteId);
  Future<void> createCita(Cita cita);
  Future<void> deleteCita(String id);
}
