import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';

abstract class DienteRepository {
  Future<List<Diente>> getDientesOdontograma(String odontogramaId);
  Future<void> guardarEstadoDiente(Diente diente);
  Future<void> eliminarEstadoDiente(String id);
}
