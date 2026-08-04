import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/paciente.dart';

abstract class IPacienteRepository {
  Future<Either<Failure, List<Paciente>>> getPacientes();

  /// Nombre y apellido de los pacientes indicados, para listados.
  ///
  /// Va contra `directorio_pacientes`, no contra `pacientes`: con el modelo de
  /// permisos de producción un doctor sólo lee la **ficha** de los pacientes
  /// que tiene asignados, pero sí puede ver consultas de otros. Sin este puente
  /// esas filas mostraban `Paciente #uuid` (defecto D4). El directorio expone
  /// únicamente id, nombre y apellido.
  Future<Either<Failure, Map<String, String>>> getNombresPacientes(
    List<String> ids,
  );
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
