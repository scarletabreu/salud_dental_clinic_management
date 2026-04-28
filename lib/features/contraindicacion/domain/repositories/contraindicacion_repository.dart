import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';

abstract class ContraindicacionRepository {
  Future<List<Contraindicacion>> getContraindicacionesPorCondicion(
    String condicionId,
  );
  Future<void> guardarContraindicacion(Contraindicacion contraindicacion);
  Future<void> eliminarContraindicacion(String id);
}
