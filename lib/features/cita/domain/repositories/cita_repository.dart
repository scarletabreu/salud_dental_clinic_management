import 'package:salud_dental_clinic_management/features/cita/domain/entities/actividad_planificada.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/referencia_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';

abstract class CitaRepository {
  /// [desde] y [hasta] acotan el rango en el servidor. Sin ellos se traen
  /// todas las citas de la historia de la clínica.
  Future<List<Cita>> getCitas({DateTime? desde, DateTime? hasta});
  Future<List<Cita>> getCitasByPaciente(
    String pacienteId, {
    DateTime? desde,
    DateTime? hasta,
  });
  Future<List<Cita>> getCitasByDoctor(
    String doctorId, {
    DateTime? desde,
    DateTime? hasta,
  });

  /// Citas de hoy en vivo (MU-1). Cada emisión es el conjunto completo de
  /// citas del día que esta sesión puede ver: RLS recorta en el servidor y el
  /// cubit re-aplica sus propios filtros de alcance y de vista.
  Stream<List<Cita>> watchCitasDeHoy();

  /// Datos programados de una cita (fecha, estado, doctor) sin ensamblar sus
  /// relaciones. `null` si la cita no existe o fue eliminada.
  Future<ReferenciaCita?> getReferenciaCita(String id);

  /// Actividades del plan del paciente que todavía pueden agendarse (SD-146).
  /// Es lo que el formulario de la cita ofrece para vincular.
  Future<List<ActividadPlanificada>> getActividadesAgendables(
    String pacienteId,
  );

  Future<void> createCita(Cita cita);

  /// Deja constancia de que el paciente ya está en la clínica.
  ///
  /// Es idempotente y la autoriza la base: el doctor puede marcar la llegada de
  /// sus propias citas sin depender de recepción, que es lo que le impedía
  /// trabajar solo (HFX-CLIN-004).
  Future<void> registrarLlegada(String citaId);

  /// Abre una atención de urgencia para un paciente que ya está presente.
  ///
  /// Crea la cita marcada como emergencia y directamente en espera. Devuelve su
  /// id para poder entrar a la consulta sin volver a buscarla en la agenda. Una
  /// urgencia no reserva agenda: queda fuera del control de solapamiento.
  Future<String> registrarEmergencia({
    required String pacienteId,
    required String doctorId,
    String? motivo,
  });
  Future<void> deleteCita(String id);
  Future<void> updateCitaEstado(String id, EstadoCita nuevoEstado);
  Future<void> updateCita(Cita cita);
}
