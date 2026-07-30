import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';

/// Vista mínima de una cita: lo justo para que una consulta sepa de qué cita
/// nació sin arrastrar el ensamblado completo de `Cita` (que resuelve doctor y
/// paciente con dos consultas extra y un RPC).
///
/// Sirve a dos usos de SD-160:
///  · heredar `fechaHora` como fecha de la consulta creada desde la cita;
///  · mostrar la cita de origen (fecha, hora, estado) en el detalle.
class ReferenciaCita {
  final String id;
  final DateTime fechaHora;
  final EstadoCita estado;
  final String doctorId;
  final String? motivo;

  const ReferenciaCita({
    required this.id,
    required this.fechaHora,
    required this.estado,
    required this.doctorId,
    this.motivo,
  });
}
