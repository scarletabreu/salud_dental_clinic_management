import 'package:dartz/dartz.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';

abstract class IPacienteRepository {
  Future<Either<Failure, List<Paciente>>> getPacientes();
  Future<Either<Failure, void>> addPaciente(Paciente paciente);
  Future<Either<Failure, void>> updatePaciente(Paciente paciente);
  Future<Either<Failure, void>> deletePaciente(String id);
}
