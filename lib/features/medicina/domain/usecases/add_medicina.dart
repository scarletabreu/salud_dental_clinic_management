import 'package:dartz/dartz.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';

class AddMedicina {
  final IMedicinaRepository repository;

  AddMedicina(this.repository);

  Future<Either<Failure, void>> call(Medicina medicina) async {
    try {
      await repository.agregarMedicina(medicina);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
