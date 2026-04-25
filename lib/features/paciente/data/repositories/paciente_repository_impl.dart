import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/repositories/i_paciente_repository.dart';
import '../datasources/paciente_remote_datasource.dart';
import '../models/paciente_model.dart';

class PacienteRepositoryImpl implements IPacienteRepository {
  final PacienteRemoteDatasource remoteDataSource;

  PacienteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Paciente>>> getPacientes() async {
    try {
      final remotePacientes = await remoteDataSource.getPacientes();
      return Right(remotePacientes);
    } catch (e) {
      return Left(ServerFailure('Error al cargar pacientes: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addPaciente(Paciente paciente) async {
    try {
      final pacienteModel = PacienteModel.fromEntity(paciente);
      await remoteDataSource.addPaciente(pacienteModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al agregar: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePaciente(Paciente paciente) async {
    try {
      final pacienteModel = PacienteModel.fromEntity(paciente);
      await remoteDataSource.updatePaciente(pacienteModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePaciente(String id) async {
    try {
      await remoteDataSource.deletePaciente(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al eliminar: $e'));
    }
  }
}
