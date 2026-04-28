import 'package:salud_dental_clinic_management/features/odontograma/data/datasources/odontograma_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/models/odontograma_model.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/repositories/odontograma_repository.dart';

class OdontogramaRepositoryImpl implements OdontogramaRepository {
  final OdontogramaRemoteDatasource remoteDataSource;

  OdontogramaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Odontograma?> getOdontogramaDeConsulta(String consultaId) async {
    final data = await remoteDataSource.fetchOdontogramaByConsulta(consultaId);
    return data != null ? OdontogramaModel.fromJson(data) : null;
  }

  @override
  Future<void> inicializarOdontograma(Odontograma odontograma) async {
    final model = OdontogramaModel(
      id: odontograma.id,
      consultaId: odontograma.consultaId,
      dientes: [],
    );
    final data = model.toJson();
    data['deleted_at'] = null;
    await remoteDataSource.crearOdontograma(data);
  }

  @override
  Future<void> guardarCambiosOdontograma(Odontograma odontograma) async {
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
  }

  @override
  Future<void> eliminarOdontograma(String id) async {
    await remoteDataSource.eliminarOdontograma(id);
  }
}
