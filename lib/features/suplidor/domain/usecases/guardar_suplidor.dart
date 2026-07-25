import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/repositories/suplidor_repository.dart';

class GuardarSuplidor {
  const GuardarSuplidor(this._repository);

  final SuplidorRepository _repository;

  Future<void> call(Suplidor suplidor) => _repository.guardarSuplidor(suplidor);
}
