import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';

abstract class IMedicinaRepository {
  Future<List<Medicina>> getCatalogoMedicinas();
  Future<void> guardarMedicina(Medicina medicina);
  Future<void> eliminarMedicina(String id);
  Future<void> agregarMedicina(Medicina medicina);
}
