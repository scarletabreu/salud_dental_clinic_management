import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/repositories/diente_repository.dart';
import 'package:salud_dental_clinic_management/features/diente/data/datasources/diente_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/diente/data/models/diente_model.dart';

class DienteRepositoryImpl implements DienteRepository {
  final DienteRemoteDatasource remoteDataSource;

  DienteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Diente>> getDientesOdontograma(String odontogramaId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchDientesByOdontograma(
        odontogramaId,
      );
      return data.map((json) => DienteModel.fromJson(json)).toList();
    }, context: 'obtener los dientes del odontograma');
  }

  @override
  Future<void> guardarEstadoDiente(Diente diente) {
    return runGuarded(() async {
      final model = DienteModel(
        id: diente.id,
        odontogramaId: diente.odontogramaId,
        superficies: diente.superficies,
        fdiCode: diente.fdiCode,
        observaciones: diente.observaciones,
      );

      await remoteDataSource.updateDiente(diente.id!, model.toJson());
    }, context: 'guardar el estado del diente');
  }

  @override
  Future<void> eliminarEstadoDiente(String id) {
    return runGuarded(
      () => remoteDataSource.deleteDienteData(id),
      context: 'eliminar los datos del diente',
    );
  }
}
