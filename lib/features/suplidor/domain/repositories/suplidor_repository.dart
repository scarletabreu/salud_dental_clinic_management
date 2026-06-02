import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';

abstract class SuplidorRepository {
  Future<List<Suplidor>> getDirectorioSuplidores();
  Future<void> guardarSuplidor(Suplidor suplidor);
  Future<void> eliminarSuplidor(String id);
}
