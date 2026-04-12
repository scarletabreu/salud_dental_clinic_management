import 'package:dartz/dartz.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';

class DeleteMedicina {
  final IMedicinaRepository repository;

  DeleteMedicina(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteMedicina(id);
  }
}
