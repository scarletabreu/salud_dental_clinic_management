import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/tipo_condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/repositories/condicion_repository.dart';
import 'package:salud_dental_clinic_management/features/condicion/data/datasources/condicion_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/condicion/data/models/condicion_model.dart';

class CondicionRepositoryImpl implements CondicionRepository {
  final CondicionRemoteDatasource remoteDataSource;

  CondicionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Condicion>> getCondiciones() async {
    try {
      final data = await remoteDataSource.fetchCondiciones();
      return data.map((json) => CondicionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error en el repositorio al obtener condiciones: $e');
    }
  }

  @override
  Future<List<Condicion>> getCondicionesByTipo(TipoCondicion tipo) async {
    try {
      final data = await remoteDataSource.fetchCondicionesByTipo(tipo.name);
      return data.map((json) => CondicionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al filtrar condiciones por tipo: $e',
      );
    }
  }

  @override
  Future<void> registrarNuevaCondicion(Condicion condicion) async {
    try {
      final model = CondicionModel(
        id: condicion.id,
        nombre: condicion.nombre,
        tipo: condicion.tipo,
        categoria: condicion.categoria,
      );
      await remoteDataSource.createCondicion(model.toJson());
    } catch (e) {
      throw Exception('Error en el repositorio al registrar condición: $e');
    }
  }

  @override
  Future<void> eliminarCondicion(String id) async {
    try {
      await remoteDataSource.deleteCondicion(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar condición: $e');
    }
  }
}
