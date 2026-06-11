import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';

abstract class CitaRepository {
  Future<List<Cita>> getCitas();
  Future<List<Cita>> getCitasByPaciente(String pacienteId);
  Future<List<Cita>> getCitasByDoctor(String doctorId);
  Future<void> createCita(Cita cita);
  Future<void> deleteCita(String id);
  Future<void> updateCitaEstado(String id, EstadoCita nuevoEstado);
  Future<void> updateCita(Cita cita);
}
