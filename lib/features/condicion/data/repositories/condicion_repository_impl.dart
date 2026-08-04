import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/tipo_condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/repositories/condicion_repository.dart';
import 'package:salud_dental_clinic_management/features/condicion/data/datasources/condicion_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/condicion/data/models/condicion_model.dart';

class CondicionRepositoryImpl implements CondicionRepository {
  final CondicionRemoteDatasource remoteDataSource;

  CondicionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Condicion>> getCondiciones() {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchCondiciones();
      return data.map((json) => CondicionModel.fromJson(json)).toList();
    }, context: 'obtener las condiciones');
  }

  @override
  Future<List<Condicion>> getCondicionesByTipo(TipoCondicion tipo) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchCondicionesByTipo(tipo.name);
      return data.map((json) => CondicionModel.fromJson(json)).toList();
    }, context: 'filtrar las condiciones por tipo');
  }

  @override
  Future<Condicion> registrarNuevaCondicion(Condicion condicion) {
    return runGuarded(() async {
      final model = CondicionModel(
        id: condicion.id,
        nombre: condicion.nombre,
        tipo: condicion.tipo,
        categoria: condicion.categoria,
      );
      final creada = await remoteDataSource.createCondicion(model.toJson());
      return CondicionModel.fromJson(creada);
    }, context: 'registrar la condición');
  }

  @override
  Future<void> eliminarCondicion(String id) {
    return runGuarded(
      () => remoteDataSource.deleteCondicion(id),
      context: 'eliminar la condición',
    );
  }
}
