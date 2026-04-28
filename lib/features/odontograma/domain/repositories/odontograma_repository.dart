import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';

abstract class OdontogramaRepository {
  Future<Odontograma?> getOdontogramaDeConsulta(String consultaId);
  Future<void> inicializarOdontograma(Odontograma odontograma);
  Future<void> guardarCambiosOdontograma(Odontograma odontograma);
  Future<void> eliminarOdontograma(String id);
}
