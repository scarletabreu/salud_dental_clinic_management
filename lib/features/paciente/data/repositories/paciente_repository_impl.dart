import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/guard.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/repositories/i_paciente_repository.dart';
import '../datasources/paciente_remote_datasource.dart';
import '../models/paciente_model.dart';

class PacienteRepositoryImpl implements IPacienteRepository {
  final PacienteRemoteDatasource remoteDataSource;

  PacienteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Paciente>>> getPacientes() {
    return guard(
      () => remoteDataSource.getPacientes(),
      context: 'cargar pacientes',
    );
  }

  @override
  Future<Either<Failure, bool>> faltaRegistro(String id) {
    return guard(
      () => remoteDataSource.esPersonaSinFichaClinica(id),
      context: 'verificar si es paciente',
    );
  }

  @override
  Future<Either<Failure, void>> addPaciente(Paciente paciente) {
    return guard(
      () => remoteDataSource.addPaciente(PacienteModel.fromEntity(paciente)),
      context: 'agregar el paciente',
    );
  }

  @override
  Future<Either<Failure, void>> updatePaciente(Paciente paciente) {
    return guard(
      () => remoteDataSource.updatePaciente(PacienteModel.fromEntity(paciente)),
      context: 'actualizar el paciente',
    );
  }

  @override
  Future<Either<Failure, Paciente>> getPacienteById(String id) {
    return guard(
      () => remoteDataSource.getPacienteById(id),
      context: 'cargar el paciente',
    );
  }

  @override
  Future<Either<Failure, Paciente>> getOrCreatePacienteByPersonaId(
    String personaId,
  ) {
    return guard(
      () => remoteDataSource.getOrCreateByPersonaId(personaId),
      context: 'cargar el paciente',
    );
  }

  @override
  Future<Either<Failure, void>> deletePaciente(String id) {
    return guard(
      () => remoteDataSource.deletePaciente(id),
      context: 'eliminar el paciente',
    );
  }

  @override
  Future<Either<Failure, String>> uploadFotoPaciente({
    required String pacienteId,
    required Uint8List bytes,
  }) {
    return guard(
      () => remoteDataSource.uploadFotoPaciente(
        pacienteId: pacienteId,
        bytes: bytes,
      ),
      context: 'subir la foto del paciente',
    );
  }
}
