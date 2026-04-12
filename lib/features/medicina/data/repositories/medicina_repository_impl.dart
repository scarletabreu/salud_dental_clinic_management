import 'package:dartz/dartz.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/data/datasources/medicine_remote_datasource.dart';

class MedicinaRepositoryImpl implements IMedicinaRepository {
  final MedicineRemoteDatasource remoteDataSource;

  MedicinaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Medicina>>> getMedicinas() async {
    try {
      final remoteMedicinas = await remoteDataSource.getMedicinas();
      return Right(remoteMedicinas);
    } catch (e) {
      return Left(
        ServerFailure('Error al cargar el catálogo de medicinas: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> addMedicina(Medicina medicina) async {
    try {
      final medicinaModel = MedicinaModel.fromEntity(medicina);
      await remoteDataSource.addMedicina(medicinaModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('No se pudo registrar la medicina: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateMedicina(Medicina medicina) async {
    try {
      final medicinaModel = MedicinaModel.fromEntity(medicina);
      await remoteDataSource.updateMedicina(medicinaModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar la medicina: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMedicina(String id) async {
    try {
      await remoteDataSource.deleteMedicina(id);
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure('No se pudo eliminar la medicina del sistema: $e'),
      );
    }
  }
}
