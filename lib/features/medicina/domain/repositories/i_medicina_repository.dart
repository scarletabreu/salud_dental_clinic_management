import 'package:dartz/dartz.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';

abstract class IMedicinaRepository {
  Future<Either<Failure, List<Medicina>>> getMedicinas();
  Future<Either<Failure, void>> addMedicina(Medicina medicina);
  Future<Either<Failure, void>> updateMedicina(Medicina medicina);
  Future<Either<Failure, void>> deleteMedicina(String id);
}
