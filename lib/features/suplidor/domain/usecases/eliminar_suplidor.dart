import 'package:salud_dental_clinic_management/features/suplidor/domain/repositories/suplidor_repository.dart';

class EliminarSuplidor {
  const EliminarSuplidor(this._repository);

  final SuplidorRepository _repository;

  Future<void> call(String id) => _repository.eliminarSuplidor(id);
}
