import 'package:salud_dental_clinic_management/features/cita/domain/entities/actividad_planificada.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/referencia_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';

abstract class CitaRepository {
  Future<List<Cita>> getCitas();
  Future<List<Cita>> getCitasByPaciente(String pacienteId);
  Future<List<Cita>> getCitasByDoctor(String doctorId);

  /// Datos programados de una cita (fecha, estado, doctor) sin ensamblar sus
  /// relaciones. `null` si la cita no existe o fue eliminada.
  Future<ReferenciaCita?> getReferenciaCita(String id);

  /// Actividades del plan del paciente que todavía pueden agendarse (SD-146).
  /// Es lo que el formulario de la cita ofrece para vincular.
  Future<List<ActividadPlanificada>> getActividadesAgendables(
    String pacienteId,
  );

  Future<void> createCita(Cita cita);
  Future<void> deleteCita(String id);
  Future<void> updateCitaEstado(String id, EstadoCita nuevoEstado);
  Future<void> updateCita(Cita cita);
}
