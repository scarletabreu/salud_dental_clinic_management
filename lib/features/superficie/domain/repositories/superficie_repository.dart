import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';

abstract class SuperficieRepository {
  Future<void> guardarEstadoSuperficie(Superficie superficie);
  Future<void> eliminarSuperficie(String id);
  Future<List<Superficie>> getSuperficiesDelDiente(String dienteId);
}
