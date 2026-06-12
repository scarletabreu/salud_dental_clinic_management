import 'package:dartz/dartz.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';

abstract class IPacienteRepository {
  Future<Either<Failure, List<Paciente>>> getPacientes();
  Future<Either<Failure, void>> addPaciente(Paciente paciente);
  Future<Either<Failure, void>> updatePaciente(Paciente paciente);
  Future<Either<Failure, void>> deletePaciente(String id);
  Future<Either<Failure, Paciente>> getPacienteById(String id);

  /// Paciente asociado a la persona [personaId]; si aún no existe, lo crea
  /// con valores por defecto (el paciente nace en su primera consulta).
  Future<Either<Failure, Paciente>> getOrCreatePacienteByPersonaId(
    String personaId,
  );
}
