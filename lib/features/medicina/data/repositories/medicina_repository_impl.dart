import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/medicina.dart';
import '../../domain/repositories/i_medicina_repository.dart';
import '../datasources/medicine_remote_datasource.dart';
import '../models/medicina_model.dart';

class MedicinaRepositoryImpl implements IMedicinaRepository {
  final MedicineRemoteDatasource remoteDataSource;

  MedicinaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Medicina>>> getMedicinas() async {
    try {
      final remoteMedicinas = await remoteDataSource.getMedicinas();
      return Right(remoteMedicinas);
    } catch (e) {
      return Left(ServerFailure('Error al cargar medicinas: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addMedicina(Medicina medicina) async {
    try {
      final medicinaModel = MedicinaModel.fromEntity(medicina);
      await remoteDataSource.addMedicina(medicinaModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al agregar: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateMedicina(Medicina medicina) async {
    try {
      final medicinaModel = MedicinaModel.fromEntity(medicina);
      await remoteDataSource.updateMedicina(medicinaModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMedicina(String id) async {
    try {
      await remoteDataSource.deleteMedicina(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al eliminar: $e'));
    }
  }
}
