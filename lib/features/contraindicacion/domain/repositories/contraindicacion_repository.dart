import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';

abstract class ContraindicacionRepository {
  Future<List<Contraindicacion>> getContraindicacionesPorCondicion(
    String condicionId,
  );
  Future<List<Contraindicacion>> getContraindicacionesPorProcedimiento(
    String procedimientoId,
  );
  Future<List<Contraindicacion>> getContraindicacionesPorTratamiento(
    String tratamientoId,
  );
  Future<List<Contraindicacion>> getContraindicacionesPorMedicina(
    String medicinaId,
  );
  Future<void> guardarContraindicacion(Contraindicacion contraindicacion);
  Future<void> eliminarContraindicacion(String id);
}
