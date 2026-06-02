import 'package:salud_dental_clinic_management/features/procedimiento/domain/entities/procedimiento.dart';

abstract class ProcedimientoRepository {
  Future<List<Procedimiento>> getCatalogoProcedimientos();
  Future<void> guardarProcedimiento(Procedimiento procedimiento);
  Future<void> eliminarProcedimiento(String id);
}
