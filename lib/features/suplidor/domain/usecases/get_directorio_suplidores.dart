import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/repositories/suplidor_repository.dart';

class GetDirectorioSuplidores {
  const GetDirectorioSuplidores(this._repository);

  final SuplidorRepository _repository;

  Future<List<Suplidor>> call() => _repository.getDirectorioSuplidores();
}
