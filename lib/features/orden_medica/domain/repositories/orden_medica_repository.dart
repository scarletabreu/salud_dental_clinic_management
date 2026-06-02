import 'package:salud_dental_clinic_management/features/orden_medica/domain/entities/orden_medica.dart';

abstract class OrdenMedicaRepository {
  Future<void> emitirOrden(OrdenMedica orden);
  Future<void> editarOrden(OrdenMedica orden);
  Future<void> anularOrden(String id);
  Future<List<OrdenMedica>> getHistorialDeOrdenes(String pacienteId);
}
