import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/evaluacion_clinica/data/datasources/evaluacion_clinica_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/evaluacion_clinica/data/models/evaluacion_clinica_model.dart';
import 'package:salud_dental_clinic_management/features/evaluacion_clinica/domain/entities/evaluacion_clinica.dart';
import 'package:salud_dental_clinic_management/features/evaluacion_clinica/domain/repositories/evaluacion_clinica_repository.dart';

class EvaluacionClinicaRepositoryImpl implements EvaluacionClinicaRepository {
  final EvaluacionClinicaRemoteDatasource remoteDataSource;

  EvaluacionClinicaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> registrarEvaluacionDeConsulta(EvaluacionClinica evaluacion) {
    return runGuarded(() async {
      final id = await remoteDataSource.asegurarEvaluacionDeConsulta(
        EvaluacionClinicaModel.fromEntity(evaluacion).toJson(),
      );

      // Los hallazgos se escriben con la consulta (guardado del odontograma);
      // aquí solo se les pone encima la evaluación a la que pertenecen.
      final consultaId = evaluacion.consultaId;
      if (consultaId != null) {
        await remoteDataSource.vincularHallazgos(
          evaluacionId: id,
          consultaId: consultaId,
        );
      }
      return id;
    }, context: 'registrar la evaluación clínica');
  }

  @override
  Future<EvaluacionClinica?> getEvaluacionDeConsulta(String consultaId) {
    return runGuarded(() async {
      final fila = await remoteDataSource.fetchPorConsulta(consultaId);
      return fila == null ? null : EvaluacionClinicaModel.fromJson(fila);
    }, context: 'obtener la evaluación de la consulta');
  }

  @override
  Future<List<EvaluacionClinica>> getEvaluacionesPaciente(String pacienteId) {
    return runGuarded(() async {
      final filas = await remoteDataSource.fetchPorPaciente(pacienteId);
      return filas.map(EvaluacionClinicaModel.fromJson).toList();
    }, context: 'obtener las evaluaciones del paciente');
  }
}
