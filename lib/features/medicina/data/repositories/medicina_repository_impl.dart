import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import '../datasources/medicina_remote_datasource.dart';
import '../models/medicina_model.dart';

class MedicinaRepositoryImpl implements IMedicinaRepository {
  final MedicinaRemoteDatasource remoteDataSource;

  MedicinaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Medicina>> getCatalogoMedicinas() async {
    final data = await remoteDataSource.fetchMedicinas();
    return data.map((json) => MedicinaModel.fromJson(json)).toList();
  }

  @override
  Future<void> agregarMedicina(Medicina medicina) async {
    await guardarMedicina(medicina);
  }

  @override
  Future<void> guardarMedicina(Medicina medicina) async {
    final model = MedicinaModel.fromEntity(medicina);
    final data = model.toJson();

    data['deleted_at'] = null;
    data['updated_at'] = DateTime.now().toIso8601String();

    await remoteDataSource.upsertMedicina(data);
  }

  @override
  Future<void> eliminarMedicina(String id) async {
    await remoteDataSource.softDeleteMedicina(id);
  }
}
