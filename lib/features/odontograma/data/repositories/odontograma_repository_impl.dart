import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/repositories/odontograma_repository.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/datasources/odontograma_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/models/odontograma_model.dart';

class OdontogramaRepositoryImpl implements OdontogramaRepository {
  final OdontogramaRemoteDatasource remoteDataSource;

  OdontogramaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Odontograma?> getOdontogramaDeConsulta(String consultaId) async {
    try {
      final data = await remoteDataSource.fetchOdontogramaByConsulta(
        consultaId,
      );
      return data != null ? OdontogramaModel.fromJson(data) : null;
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener odontograma de la consulta: $e',
      );
    }
  }

  @override
  Future<void> inicializarOdontograma(Odontograma odontograma) async {
    try {
      final model = OdontogramaModel(
        id: odontograma.id,
        consultaId: odontograma.consultaId,
        dientes: [],
      );
      final data = model.toJson();
      data['deleted_at'] = null;
      await remoteDataSource.crearOdontograma(data);
    } catch (e) {
      throw Exception('Error en el repositorio al inicializar odontograma: $e');
    }
  }

  @override
  Future<void> guardarCambiosOdontograma(Odontograma odontograma) async {
    try {
      final model = OdontogramaModel(
        id: odontograma.id,
        consultaId: odontograma.consultaId,
        dientes: odontograma.dientes,
        tratamientos: odontograma.tratamientos,
        diagnosis: odontograma.diagnosis,
      );

      final data = model.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      await remoteDataSource.actualizarOdontograma(data);
    } catch (e) {
      throw Exception(
        'Error en el repositorio al guardar cambios del odontograma: $e',
      );
    }
  }

  @override
  Future<void> eliminarOdontograma(String id) async {
    try {
      await remoteDataSource.eliminarOdontograma(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar odontograma: $e');
    }
  }
}
