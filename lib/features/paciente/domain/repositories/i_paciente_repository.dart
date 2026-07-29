import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/paciente.dart';

abstract class IPacienteRepository {
  Future<Either<Failure, List<Paciente>>> getPacientes();
  Future<Either<Failure, bool>> faltaRegistro(String id);

  /// Devuelve el id del paciente creado.
  Future<Either<Failure, String>> addPaciente(Paciente paciente);
  Future<Either<Failure, void>> updatePaciente(Paciente paciente);
  Future<Either<Failure, Paciente>> getPacienteById(String id);
  Future<Either<Failure, Paciente>> getOrCreatePacienteByPersonaId(
    String personaId,
  );
  Future<Either<Failure, void>> deletePaciente(String id);
  Future<Either<Failure, String>> uploadFotoPaciente({
    required String pacienteId,
    required Uint8List bytes,
  });
}
