import 'package:dartz/dartz.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';

class GetMedicinas {
  final IMedicinaRepository repository;

  GetMedicinas(this.repository);

  Future<Either<Failure, List<Medicina>>> call() async {
    try {
      final medicinas = await repository.getCatalogoMedicinas();
      return Right(medicinas);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
