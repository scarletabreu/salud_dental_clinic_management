import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/repositories/diente_repository.dart';
import 'package:salud_dental_clinic_management/features/diente/data/datasources/diente_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/diente/data/models/diente_model.dart';

class DienteRepositoryImpl implements DienteRepository {
  final DienteRemoteDatasource remoteDataSource;

  DienteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Diente>> getDientesOdontograma(String odontogramaId) async {
    try {
      final data = await remoteDataSource.fetchDientesByOdontograma(
        odontogramaId,
      );
      return data.map((json) => DienteModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener dientes del odontograma: $e',
      );
    }
  }

  @override
  Future<void> guardarEstadoDiente(Diente diente) async {
    try {
      final model = DienteModel(
        id: diente.id,
        odontogramaId: diente.odontogramaId,
        superficies: diente.superficies,
        fdiCode: diente.fdiCode,
        observaciones: diente.observaciones,
      );

      await remoteDataSource.updateDiente(diente.id!, model.toJson());
    } catch (e) {
      throw Exception(
        'Error en el repositorio al guardar estado del diente: $e',
      );
    }
  }

  @override
  Future<void> eliminarEstadoDiente(String id) async {
    try {
      await remoteDataSource.deleteDienteData(id);
    } catch (e) {
      throw Exception(
        'Error en el repositorio al eliminar datos del diente: $e',
      );
    }
  }
}
