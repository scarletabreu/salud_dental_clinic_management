import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/tipo_condicion.dart';

abstract class CondicionRepository {
  Future<List<Condicion>> getCondiciones();
  Future<List<Condicion>> getCondicionesByTipo(TipoCondicion tipo);
  /// Registra una condición en el catálogo y devuelve la entidad con su `id`.
  Future<Condicion> registrarNuevaCondicion(Condicion condicion);
  Future<void> eliminarCondicion(String id);
}
